
#----------------------------------------------------------------------------------------------------------------
#   Configure SQL Server Logins
#----------------------------------------------------------------------------------------------------------------
if($skipSQLLogins) {
    Write-Host "Skipping configuration of SQL Server Users"    
}
else {
    Write-Host "Configuring SQL Server Users"
    $databases = @($stagingdb_name, $sampledb_name, $metadatadb_name)

    $aadUsers =  @($datafactory_name)
    
    if(!$purview_sp_id -eq 0)
    {
        $aadUsers +=  $purview_name
        $aadUsers +=  $purview_sp_name
    }
    
    $token=$(az account get-access-token --resource=https://database.windows.net --query accessToken --output tsv)
    foreach($database in $databases)
    {
        
        foreach($user in $aadUsers)        
        {
            if (![string]::IsNullOrEmpty($user))
            {
                $sqlcommand = "
                        DROP USER IF EXISTS [$user] 
                        CREATE USER [$user] FROM EXTERNAL PROVIDER;
                        ALTER ROLE db_datareader ADD MEMBER [$user];
                        ALTER ROLE db_datawriter ADD MEMBER [$user];
                        GRANT EXECUTE ON SCHEMA::[dbo] TO [$user];
                        GO
                "
    
                write-host "Granting MSI Privileges on $database DB to $user"
                Invoke-Sqlcmd -ServerInstance "$sqlserver_name.database.windows.net,1433" -Database $database -AccessToken $token -query $sqlcommand    
            }
        }
    }
    
    $ddlCommand = "ALTER ROLE db_ddladmin ADD MEMBER [$datafactory_name];"
    foreach($database in $databases)
    {
            write-host "Granting DDL Role on $database DB to $datafactory_name"
            Invoke-Sqlcmd -ServerInstance "$sqlserver_name.database.windows.net,1433" -Database $database -AccessToken $token -query $ddlCommand   
    }
    
}

#----------------------------------------------------------------------------------------------------------------
#   Configure Synapse Logins
#----------------------------------------------------------------------------------------------------------------
if($skipSynapseLogins) {
    Write-Host "Skipping configuration of Synapse SQL Users"    
}
else {
    Write-Host "Configuring Synapse SQL Users"

    #Add Ip to SQL Firewall
    #$result = az synapse workspace update -n $synapse_workspace_name -g $resource_group_name  --set publicNetworkAccess="Enabled"
    $result = az synapse workspace firewall-rule create --resource-group $resource_group_name --workspace-name $synapse_workspace_name --name "Deploy.ps1" --start-ip-address $myIp --end-ip-address $myIp

    if ($tout.is_vnet_isolated -eq $false)
    {
        $result = az synapse workspace firewall-rule create --resource-group $resource_group_name --workspace-name $synapse_workspace_name --name "AllowAllWindowsAzureIps" --start-ip-address "0.0.0.0" --end-ip-address "0.0.0.0"
    }

    if([string]::IsNullOrEmpty($synapse_sql_pool_name) )
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
        if ((![string]::IsNullOrEmpty($datafactory_name)) -and ($synapse_sql_pool_name -ne 'Dummy') -and (![string]::IsNullOrEmpty($synapse_sql_pool_name)))
        {
            # For a Spark user to read and write directly from Spark into or from a SQL pool, db_owner permission is required.
            Invoke-Sqlcmd -ServerInstance "$synapse_workspace_name.sql.azuresynapse.net,1433" -Database $synapse_sql_pool_name -AccessToken $token -query "IF NOT EXISTS (SELECT name
    FROM [sys].[database_principals]
    WHERE [type] = 'E' AND name = N'$datafactory_name') BEGIN CREATE USER [$datafactory_name] FROM EXTERNAL PROVIDER END"    
            Invoke-Sqlcmd -ServerInstance "$synapse_workspace_name.sql.azuresynapse.net,1433" -Database $synapse_sql_pool_name -AccessToken $token -query "EXEC sp_addrolemember 'db_owner', '$datafactory_name'"
        }
    }


}