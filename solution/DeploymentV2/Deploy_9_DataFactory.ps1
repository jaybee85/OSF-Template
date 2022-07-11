#----------------------------------------------------------------------------------------------------------------
#   Deploy Data Factory Pipelines
#----------------------------------------------------------------------------------------------------------------
if ($skipDataFactoryPipelines) {
    Write-Host "Skipping DataFactory Pipelines"    
}
else {
    Set-Location $deploymentFolderPath    
    #Add Ip to SQL Firewall
    $result = az sql server update -n $sqlserver_name -g $resource_group_name  --set publicNetworkAccess="Enabled"
    $result = az sql server firewall-rule create -g $resource_group_name -s $sqlserver_name -n "Deploy.ps1" --start-ip-address $myIp --end-ip-address $myIp
    #Allow Azure services and resources to access this server
    $result = az sql server firewall-rule create -g $resource_group_name -s $sqlserver_name -n "Azure" --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
    
    $SqlInstalled = Get-InstalledModule SqlServer
    if($null -eq $SqlInstalled)
    {
        write-host "Installing SqlServer Module"
        Install-Module -Name SqlServer -Scope CurrentUser -Force
    }

    Invoke-Expression ./GenerateAndUploadADFPipelines.ps1
    Set-Location $deploymentFolderPath

    
}