function DeployDataFactoryAndSynapseArtefacts (    
    [Parameter(Mandatory = $true)]
    [pscustomobject]$tout = $false,
    [Parameter(Mandatory = $true)]
    [string]$deploymentFolderPath = "",
    [Parameter(Mandatory = $true)]
    [String]$PathToReturnTo = ""
) {
    #----------------------------------------------------------------------------------------------------------------
    #   Deploy Data Factory Pipelines
    #----------------------------------------------------------------------------------------------------------------
    if ($skipDataFactoryPipelines) {
        Write-Host "Skipping DataFactory Pipelines"    
    }
    else {
        #needed for git integration
        az extension add --upgrade --name datafactory
        
        Set-Location $deploymentFolderPath    
        #Add Ip to SQL Firewall
        $myIp = $env:TF_VAR_ip_address
        $myIp2 = $env:TF_VAR_ip_address2
    
        if ($myIp -ne $null) {
            $result = az sql server firewall-rule create -g $tout.resource_group_name -s $tout.sqlserver_name -n "DeploymentAgent" --start-ip-address $myIp --end-ip-address $myIp
        }
        if ($myIp2 -ne $null) {        
            $result = az sql server firewall-rule create -g $tout.resource_group_name -s $tout.sqlserver_name -n "DeploymentUser" --start-ip-address $myIp2 --end-ip-address $myIp2
        }
    
        $SqlInstalled = Get-InstalledModule SqlServer
        if ($null -eq $SqlInstalled) {
            write-host "Installing SqlServer Module"
            Install-Module -Name SqlServer -Scope CurrentUser -Force
        }

        Import-Module ./pwshmodules/GenerateAndUploadADFPipelines.psm1 -force
        GenerateAndUploadDataFactoryAndSynapseArtefacts -tout $tout  -deploymentFolderPath $deploymentFolderPath -PathToReturnTo $PathToReturnTo          

        if([string]::IsNullOrEmpty($PathToReturnTo) -ne $true)
        {
            Write-Debug "Returning to $PathToReturnTo"
            Set-Location $PathToReturnTo
        }
        else {
            Write-Debug "Path to return to is null"
        }

    
    }
}