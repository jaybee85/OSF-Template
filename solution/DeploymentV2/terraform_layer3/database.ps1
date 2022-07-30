param (
    [Parameter(Mandatory = $true)]
    [pscustomobject]$tout = $false,
    [Parameter(Mandatory = $true)]
    [string]$deploymentFolderPath = "",
    [Parameter(Mandatory = $true)]
    [String]$PathToReturnTo = "",
    [Parameter(Mandatory = $true)]
    [bool]$PublishSQLLogins   
)

#----------------------------------------------------------------------------------------------------------------
#   Configure SQL Server Logins
#----------------------------------------------------------------------------------------------------------------
if($PublishSQLLogins -eq $false) {
    Write-Host "Skipping configuration of SQL Server Users"    
}
else {
    Write-Host "Configuring SQL Server Users"
    $databases = @($tout.stagingdb_name, $tout.sampledb_name, $tout.metadatadb_name)

    $aadUsers =  @($tout.datafactory_name,$tout.functionapp_name, $tout.webapp_name )
    
    if($env:TF_VAR_deploy_purview -eq $true)
    {
        $aadUsers +=  ($tout.purview_name)
        #$aadUsers +=  ($tout.purview_sp_name)
    }
    
    $sqladmins = ($env:TF_VAR_azure_sql_aad_administrators | ConvertFrom-Json -Depth 10)
    $sqladmins2 = ($Sqladmins | Get-Member)  | Where-Object {$_.MemberType -eq "NoteProperty"} | Select-Object -Property Name
    foreach($user in $sqladmins2)
    {
        if($user.Name -ne "sql_aad_admin")
        {
            $aadUsers += $user.Name
        }
    }


    $token=$(az account get-access-token --resource=https://database.windows.net --query accessToken --output tsv)
    foreach($database in $databases)
    {
        
        foreach($user in $aadUsers)        
        {
            if (![string]::IsNullOrEmpty($user))
            {
                $sqlcommand = "

                IF NOT EXISTS (SELECT *
                FROM [sys].[database_principals]
                WHERE [type] = N'E' AND [name] = N'$user') 
                BEGIN
                    CREATE USER [$user] FROM EXTERNAL PROVIDER;		
                END
                ALTER ROLE db_datareader ADD MEMBER [$user];
                ALTER ROLE db_datawriter ADD MEMBER [$user];
                GRANT EXECUTE ON SCHEMA::[dbo] TO [$user];
                GO
                        
                "
    
                write-host "Granting MSI Privileges on $database DB to $user"
                Invoke-Sqlcmd -ServerInstance "$($tout.sqlserver_name).database.windows.net,1433" -Database $database -AccessToken $token -query $sqlcommand    
            }
        }
    }
    
    $ddlCommand = "ALTER ROLE db_ddladmin ADD MEMBER [$($tout.datafactory_name)];"
    foreach($database in $databases)
    {
            write-host "Granting DDL Role on $database DB to $($tout.datafactory_name)"
            Invoke-Sqlcmd -ServerInstance "$($tout.sqlserver_name).database.windows.net,1433" -Database $database -AccessToken $token -query $ddlCommand   
    }
    
}

#----------------------------------------------------------------------------------------------------------------
#   Configure Synapse Logins
#----------------------------------------------------------------------------------------------------------------
if($PublishSQLLogins -eq $false) {
    Write-Host "Skipping configuration of Synapse SQL Users"    
}
else {
    Write-Host "Configuring Synapse SQL Users"

    $myIp = $env:TF_VAR_ip_address
    $myIp2 = $env:TF_VAR_ip_address2

    #Add Ip to SQL Firewall
    #$result = az synapse workspace update -n $synapse_workspace_name -g $resource_group_name  --set publicNetworkAccess="Enabled"
    $result = az synapse workspace firewall-rule create --resource-group $tout.resource_group_name --workspace-name $tout.synapse_workspace_name --name "DeploymentAgent" --start-ip-address $myIp --end-ip-address $myIp
    $result = az synapse workspace firewall-rule create --resource-group $tout.resource_group_name --workspace-name $tout.synapse_workspace_name --name "DeploymentUser" --start-ip-address $myIp2 --end-ip-address $myIp2

    if ($tout.is_vnet_isolated -eq $false)
    {
        $result = az synapse workspace firewall-rule create --resource-group $tout.resource_group_name --workspace-name $tout.synapse_workspace_name --name "AllowAllWindowsAzureIps" --start-ip-address "0.0.0.0" --end-ip-address "0.0.0.0"
    }

    if([string]::IsNullOrEmpty($tout.synapse_sql_pool_name) )
    {
        write-host "Synapse pool is not deployed."
    }
    else 
    {
        # Fix the MSI registrations on the other databases. I'd like a better way of doing this in the future
        $SqlInstalled = Get-InstalledModule SqlServer
        if($null -eq $SqlInstalled)
        {
            write-host "Installing SqlServer Module"
            Install-Module -Name SqlServer -Scope CurrentUser -Force
        }



        $token=$(az account get-access-token --resource=https://sql.azuresynapse.net --query accessToken --output tsv)
        if ((![string]::IsNullOrEmpty($tout.datafactory_name)) -and ($tout.synapse_sql_pool_name -ne 'Dummy') -and (![string]::IsNullOrEmpty($tout.synapse_sql_pool_name)))
        {            
            # For a Spark user to read and write directly from Spark into or from a SQL pool, db_owner permission is required.
            Invoke-Sqlcmd -ServerInstance "$($tout.synapse_workspace_name).sql.azuresynapse.net,1433" -Database $tout.synapse_sql_pool_name -AccessToken $token -query "IF NOT EXISTS (SELECT name
            FROM [sys].[database_principals]
            WHERE [type] = 'E' AND name = N'$($tout.datafactory_name)') BEGIN CREATE USER [$($tout.datafactory_name)] FROM EXTERNAL PROVIDER END"    
            Invoke-Sqlcmd -ServerInstance "$($tout.synapse_workspace_name).sql.azuresynapse.net,1433" -Database $tout.synapse_sql_pool_name -AccessToken $token -query "EXEC sp_addrolemember 'db_owner', '$($tout.datafactory_name)'"
        }
    }


}