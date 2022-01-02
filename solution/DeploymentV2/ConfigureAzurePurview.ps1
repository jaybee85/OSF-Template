$subscriptionId = '<<subscriptionId>>'
$resourceGroupName = '<<resource group name>>'
$tenantId = '<<aad tenant id>>'
$purviewServicePrincipalId = '<<Object Id of the AAD service principal created for purview>>'
$purviewName = '<<the name of hte purview account name>>'
$lockboxName = "<< a friendly name for you purview account>>"
$keyVaultName = "<< the keyvault name that purview will use for secrets >>"
$blobName = "<< the storage account created for the lockbox >>"
$adlsName = "<< the data lake account created for the lockbox >>"
$sqlServerName = "<< the sql server name of the SQL server used in the environment>>"
$dataFactoryName = "<< the name of the data factory to get lineage data from >>"

$integrationRuntimeName = "AzureIntegrationRuntime"
$purviewEndpoint = "https://$purviewName.purview.azure.com"

function CallPurviewApi (
    [string] $Method,
    [string] $Url,
    [string] $Body
) {

    $Headers = @{}
    $Headers.Add("Accept","*/*")
    $Headers.Add("User-Agent","Windows PowerShell 7.x Purview API PS")
    $Headers.Add("Authorization","Bearer $($AccessTokenData.Token)")
    $Headers.Add("Content-Type","application/json")
    Write-Host "Invoking API : Sending Request ... " -ForegroundColor DarkCyan -NoNewLine
    Write-Host "  $Method   $Url"

    Try {
        $result = Invoke-RestMethod -Method $Method -Uri $Url -Headers $Headers -Body $Body
    } Catch {
        Write-Host $_ :-> $_.Exception
    }

    Write-Host "API Response Received :-> " -ForegroundColor Green
    Write-Output $result
}
# Login to Azure PowerShell
# Connect-AzAccount
Set-AzContext -Tenant $tenantId -Subscription $subscriptionId
$AccessTokenData = (Get-AzAccessToken -ResourceUrl "https://purview.azure.net")

#----------------------------------------------------------------------------------------------------------------
# Create a friendly name for the purview account
#----------------------------------------------------------------------------------------------------------------
$body = '{
    "friendlyName": "'+$lockboxName+'"
  }'
$uri = "$purviewEndpoint/?api-version=2019-11-01-preview"
CallPurviewApi -Method "PATCH" -Url $uri -Body $body

#----------------------------------------------------------------------------------------------------------------
# Create the self hosted IR
#----------------------------------------------------------------------------------------------------------------
$body = '{"name":"AzureIntegrationRuntime","properties":{"type":"SelfHosted"}}'
$uri = "https://$purviewName.purview.azure.com/proxy/integrationRuntimes/AzureIntegrationRuntime?api-version=2020-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body

#----------------------------------------------------------------------------------------------------------------
# Create a shared credential source 
#----------------------------------------------------------------------------------------------------------------
# Link the keyvault so we can get secrets to access the data sources
$body = '{
    "properties": {
      "baseUrl": "https://'+$keyVaultName+'.vault.azure.net/",
      "description": "Lockbox KeyVault"
    }
  }'
$uri = "$purviewEndpoint/scan/azureKeyVaults/$keyVaultName"+"?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body

# Configure the credentials for the source
$body = '{"name":"SPCredentials","properties":{"type":"ServicePrincipal","typeProperties":{"tenant":"'+$tenantId+'","servicePrincipalId":"'+$purviewServicePrincipalId+'","servicePrincipalKey":{"type":"AzureKeyVaultSecret","secretName":"AzurePurviewIr","secretVersion":"","store":{"referenceName":"'+$keyVaultName+'","type":"LinkedServiceReference"}}}}}'
$uri = "$purviewEndpoint/proxy/credentials/SPCredentials?api-version=2020-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body

#----------------------------------------------------------------------------------------------------------------
# Create the azure sql database - data source
#----------------------------------------------------------------------------------------------------------------
$body = '{"kind":"AzureSqlDatabase","name":"'+$sqlServerName+'","properties":{"serverEndpoint":"'+$sqlServerName+'.database.windows.net","subscriptionId":"'+$subscriptionId+'","resourceGroup":"'+$resourceGroupName+'","location":"australiaeast","resourceName":"'+$sqlServerName+'","resourceId":"/subscriptions/'+$subscriptionId+'/resourceGroups/'+$resourceGroupName+'/providers/Microsoft.Sql/servers/'+$sqlServerName+'","collection":{"type":"CollectionReference","referenceName":"'+$purviewName+'"}}}'
$uri = "$purviewEndpoint/scan/datasources/$sqlServerName"+"?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body

# Configure the scan for the source (x3 databases)
#----------------------------------------------------------------------------------------------------------------
$body = '{"name":"SqlScanWeeklyMeta","kind":"AzureSqlDatabaseCredential","properties":{"connectedVia":{"referenceName":"'+$integrationRuntimeName+'"},"serverEndpoint":"'+$sqlServerName+'.database.windows.net","databaseName":"MetadataDb","credential":{"referenceName":"SPCredentials","credentialType":"ServicePrincipal"},"collection":{"type":"CollectionReference","referenceName":"'+$purviewName+'"},"scanRulesetType":"System","scanRulesetName":"AzureSqlDatabase"}}'
$uri = "$purviewEndpoint/scan/datasources/"+$sqlServerName+"/scans/SqlScanWeeklyMeta?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body
# Schedule
$body = '{"name":"default","properties":{"scanLevel":"Incremental","recurrence":{"startTime":"2021-12-30T18:37:00Z","interval":1,"frequency":"Week","timezone":"UTC","schedule":{"hours":[3],"minutes":[0],"weekDays":["Sunday"]}}}}'
$uri = "$purviewEndpoint/scan/datasources/"+$sqlServerName+"/scans/SqlScanWeeklyMeta/triggers/default?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body
# Filter
$body = '{"properties":{"excludeUriPrefixes":[],"includeUriPrefixes":["mssql://'+$sqlServerName+'.windows.net/MetadataDb/"]}}'
$uri = "$purviewEndpoint/scan/datasources/"+$sqlServerName+"/scans/SqlScanWeeklyMeta/filters/custom?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body
#----------------------------------------------------------------------------------------------------------------
$body = '{"name":"SqlScanWeeklyStaging","kind":"AzureSqlDatabaseCredential","properties":{"connectedVia":{"referenceName":"'+$integrationRuntimeName+'"},"serverEndpoint":"'+$sqlServerName+'.database.windows.net","databaseName":"Staging","credential":{"referenceName":"SPCredentials","credentialType":"ServicePrincipal"},"collection":{"type":"CollectionReference","referenceName":"'+$purviewName+'"},"scanRulesetType":"System","scanRulesetName":"AzureSqlDatabase"}}'
$uri = "$purviewEndpoint/scan/datasources/"+$sqlServerName+"/scans/SqlScanWeeklyStaging?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body
# Schedule
$body = '{"name":"default","properties":{"scanLevel":"Incremental","recurrence":{"startTime":"2021-12-30T18:37:00Z","interval":1,"frequency":"Week","timezone":"UTC","schedule":{"hours":[3],"minutes":[0],"weekDays":["Sunday"]}}}}'
$uri = "$purviewEndpoint/scan/datasources/"+$sqlServerName+"/scans/SqlScanWeeklyStaging/triggers/default?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body
# Filter
$body = '{"properties":{"excludeUriPrefixes":[],"includeUriPrefixes":["mssql://'+$sqlServerName+'.windows.net/Staging/"]}}'
$uri = "$purviewEndpoint/scan/datasources/"+$sqlServerName+"/scans/SqlScanWeeklyStaging/filters/custom?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body
#----------------------------------------------------------------------------------------------------------------
$body = '{"name":"SqlScanWeeklySamples","kind":"AzureSqlDatabaseCredential","properties":{"connectedVia":{"referenceName":"'+$integrationRuntimeName+'"},"serverEndpoint":"'+$sqlServerName+'.database.windows.net","databaseName":"Samples","credential":{"referenceName":"SPCredentials","credentialType":"ServicePrincipal"},"collection":{"type":"CollectionReference","referenceName":"'+$purviewName+'"},"scanRulesetType":"System","scanRulesetName":"AzureSqlDatabase"}}'
$uri = "$purviewEndpoint/scan/datasources/"+$sqlServerName+"/scans/SqlScanWeeklySamples?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body
# Schedule
$body = '{"name":"default","properties":{"scanLevel":"Incremental","recurrence":{"startTime":"2021-12-30T18:37:00Z","interval":1,"frequency":"Week","timezone":"UTC","schedule":{"hours":[3],"minutes":[0],"weekDays":["Sunday"]}}}}'
$uri = "$purviewEndpoint/scan/datasources/"+$sqlServerName+"/scans/SqlScanWeeklySamples/triggers/default?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body
# Filter
$body = '{"properties":{"excludeUriPrefixes":[],"includeUriPrefixes":["mssql://'+$sqlServerName+'.windows.net/Samples/"]}}'
$uri = "$purviewEndpoint/scan/datasources/"+$sqlServerName+"/scans/SqlScanWeeklySamples/filters/custom?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body

#----------------------------------------------------------------------------------------------------------------
# Create the Azure Blob storage - data source
#----------------------------------------------------------------------------------------------------------------
$body = '{"kind":"AzureStorage","name":"'+$blobName+'","properties":{"endpoint":"https://'+$blobName+'.blob.core.windows.net/","subscriptionId":"'+$subscriptionId+'","resourceGroup":"'+$resourceGroupName+'","location":"australiaeast","resourceName":"'+$blobName+'","resourceId":"/subscriptions/'+$subscriptionId+'/resourceGroups/'+$resourceGroupName+'/providers/Microsoft.Storage/storageAccounts/'+$blobName+'","collection":{"type":"CollectionReference","referenceName":"'+$purviewName+'"},"dataUseGovernance":"Disabled"}}'
$uri = "$purviewEndpoint/scan/datasources/"+$blobName+"?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body

# Configure the scan
$body = '{"name":"BlobScanWeekly","kind":"AzureStorageCredential","properties":{"connectedVia":{"referenceName":"'+$integrationRuntimeName+'"},"credential":{"referenceName":"SPCredentials","credentialType":"ServicePrincipal"},"collection":{"type":"CollectionReference","referenceName":"'+$purviewName+'"},"scanRulesetType":"System","scanRulesetName":"AzureStorage"}}'
$uri = "$purviewEndpoint/scan/datasources/"+$blobName+"/scans/BlobScanWeekly?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body

# Schedule
$body = '{"name":"default","properties":{"scanLevel":"Incremental","recurrence":{"startTime":"2021-12-30T18:37:00Z","interval":1,"frequency":"Week","timezone":"UTC","schedule":{"hours":[3],"minutes":[0],"weekDays":["Sunday"]}}}}'
$uri = "$purviewEndpoint/scan/datasources/"+$blobName+"/scans/BlobScanWeekly/triggers/default?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body

# Filter
$body = '{"properties":{"excludeUriPrefixes":[],"includeUriPrefixes":["https://'+$blobName+'.blob.core.windows.net/"]}}'
$uri = "$purviewEndpoint/scan/datasources/"+$blobName+"/scans/BlobScanWeekly/filters/custom?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body
#----------------------------------------------------------------------------------------------------------------
# Create the Data Lake storage - data source
#----------------------------------------------------------------------------------------------------------------
$body = '{"kind":"AdlsGen2","name":"'+$adlsName+'","properties":{"endpoint":"https://'+$adlsName+'.dfs.core.windows.net/","subscriptionId":"'+$subscriptionId+'","resourceGroup":"'+$resourceGroupName+'","location":"australiaeast","resourceName":"'+$adlsName+'","resourceId":"/subscriptions/'+$subscriptionId+'/resourceGroups/'+$resourceGroupName+'/providers/Microsoft.Storage/storageAccounts/'+$adlsName+'","collection":{"type":"CollectionReference","referenceName":"'+$purviewName+'"},"dataUseGovernance":"Disabled"}}'
$uri = "$purviewEndpoint/scan/datasources/"+$adlsName+"?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body

$uri = "$purviewEndpoint/scan/datasources/"+$adlsName+"/scans/AdlsScanWeekly?api-version=2018-12-01-preview"
$body = '{"name":"AdlsScanWeekly","kind":"AdlsGen2Credential","properties":{"connectedVia":{"referenceName":"'+$integrationRuntimeName+'"},"credential":{"referenceName":"SPCredentials","credentialType":"ServicePrincipal"},"collection":{"type":"CollectionReference","referenceName":"'+$purviewName+'"},"scanRulesetType":"System","scanRulesetName":"AdlsGen2"}}'
CallPurviewApi -Method "PUT" -Url $uri  -Body $body

# Schedule
$body = '{"name":"default","properties":{"scanLevel":"Incremental","recurrence":{"startTime":"2021-12-30T18:37:00Z","interval":1,"frequency":"Week","timezone":"UTC","schedule":{"hours":[4],"minutes":[0],"weekDays":["Sunday"]}}}}'
$uri = "$purviewEndpoint/scan/datasources/"+$adlsName+"/scans/AdlsScanWeekly/triggers/default?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body

# Filter
$body = '{"properties":{"excludeUriPrefixes":[],"includeUriPrefixes":["https://'+$adlsName+'.dfs.core.windows.net/"]}}'
$uri = "$purviewEndpoint/scan/datasources/"+$adlsName+"/scans/AdlsScanWeekly/filters/custom?api-version=2018-12-01-preview"
CallPurviewApi -Method "PUT" -Url $uri  -Body $body
#----------------------------------------------------------------------------------------------------------------
# Configure the datafactory link
#----------------------------------------------------------------------------------------------------------------
$uri ="/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.DataFactory/factories/"+$dataFactoryName+"?api-version=2018-06-01"
$body = '{"tags":{"catalogUri":"https://'+$purviewName+'.purview.azure.com/catalog"}, "properties":{"purviewConfiguration":{"purviewResourceId":"/subscriptions/'+$subscriptionId+'/resourceGroups/'+$resourceGroupName+'/providers/Microsoft.Purview/accounts/'+$purviewName+'"}}}'
Invoke-AzRestMethod -Path $uri -Method 'PATCH' -Payload $body
