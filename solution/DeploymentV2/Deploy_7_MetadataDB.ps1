#----------------------------------------------------------------------------------------------------------------
#   Populate the Metadata Database
#----------------------------------------------------------------------------------------------------------------
if($skipDatabase) {
    Write-Host "Skipping Populating Metadata Database"    
}
else {
    
    Write-Host "Populating Metadata Database"

    Set-Location $deploymentFolderPath
    Set-Location "..\Database\ADSGoFastDbUp\AdsGoFastDbUp"
    dotnet restore
    dotnet publish --no-restore --configuration Release --output '..\..\..\DeploymentV2\bin\publish\unzipped\database\'
    
    #Add Ip to SQL Firewall
    $result = az sql server update -n $sqlserver_name -g $resource_group_name  --set publicNetworkAccess="Enabled"
    $result = az sql server firewall-rule create -g $resource_group_name -s $sqlserver_name -n "Deploy.ps1" --start-ip-address $myIp --end-ip-address $myIp
    #Allow Azure services and resources to access this server
    $result = az sql server firewall-rule create -g $resource_group_name -s $sqlserver_name -n "Azure" --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

    Set-Location $deploymentFolderPath
    Set-Location ".\bin\publish\unzipped\database\"

    $lake_database_container_name = $tout.synapse_lakedatabase_container_name

    # This has been updated to use the Azure CLI cred
    dotnet AdsGoFastDbUp.dll -a True -c "Data Source=tcp:${sqlserver_name}.database.windows.net;Initial Catalog=${metadatadb_name};" -v True --DataFactoryName $datafactory_name --ResourceGroupName $resource_group_name --KeyVaultName $keyvault_name --LogAnalyticsWorkspaceId $loganalyticsworkspace_id --SubscriptionId $subscription_id --SampleDatabaseName $sampledb_name --StagingDatabaseName $stagingdb_name --MetadataDatabaseName $metadatadb_name --BlobStorageName $blobstorage_name --AdlsStorageName $adlsstorage_name --WebAppName $webapp_name --FunctionAppName $functionapp_name --SqlServerName $sqlserver_name --SynapseWorkspaceName $synapse_workspace_name --SynapseDatabaseName $synapse_sql_pool_name --SynapseSQLPoolName $synapse_sql_pool_name --SynapseSparkPoolName $synapse_spark_pool_name --PurviewAccountName $purview_name --SynapseLakeDatabaseContainerName $lake_database_container_name
    
    # Fix the MSI registrations on the other databases. I'd like a better way of doing this in the future
    $SqlInstalled = false
    try { 
        $SqlInstalled = Get-InstalledModule SqlServer
    }
    catch { "SqlServer PowerShell module not installed." }
    
    if($null -eq $SqlInstalled)
    {
        write-host "Installing SqlServer Module"
        Install-Module -Name SqlServer -Scope CurrentUser -Force
    }

    $databases = @($stagingdb_name, $sampledb_name, $metadatadb_name)
 	#SIFDatabase
 	if (!$skipSIF){
        $databases = @($stagingdb_name, $sampledb_name, $sifdb_name ,$metadatadb_name)
        Set-Location $deploymentFolderPath
        Set-Location "..\Database\ADSGoFastDbUp\SIF"
        dotnet restore
        dotnet publish --no-restore --configuration Release --output '..\..\..\DeploymentV2\bin\publish\unzipped\database\' 
        
        Set-Location $deploymentFolderPath
        Set-Location ".\bin\publish\unzipped\database\"
        
        $synapse_sql_serverless_name = "${synapse_workspace_name}-ondemand.sql.azuresynapse.net"
        $AdlsStorageurl =  "https://${adlsstorage_name}.blob.core.windows.net/datalakelanding"


        dotnet SIF.dll -a True -c "Data Source=tcp:$synapse_sql_serverless_name;Initial Catalog=master;" -v True --DataFactoryName $datafactory_name --ResourceGroupName $resource_group_name `
                       --KeyVaultName $keyvault_name --LogAnalyticsWorkspaceId $loganalyticsworkspace_id --SubscriptionId $subscription_id  --WebAppName $webapp_name `
                       --FunctionAppName $functionapp_name --SqlServerName $sqlserver_name --SynapseWorkspaceName $synapse_workspace_name  --SynapseSQLPoolName $synapse_sql_pool_name `
                       --SynapseDatabaseName $sifdb_name --SIFDatabaseName $sifdb_name --RelativePath $RelativePath --AdlsStorageName $AdlsStorageurl
    
    } else {
        $databases = @($stagingdb_name, $sampledb_name ,$metadatadb_name)
    }
    
    Set-Location $deploymentFolderPath

}