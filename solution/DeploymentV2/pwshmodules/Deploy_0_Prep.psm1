function PrepareDeployment (
    [Parameter(Mandatory=$true)]
    [System.Boolean]$gitDeploy=$false,
    [Parameter(Mandatory=$true)]
    [String]$deploymentFolderPath,
    [Parameter(Mandatory=$true)]
    [String]$FeatureTemplate,
    [Parameter(Mandatory=$false)]
    [String]$PathToReturnTo=""
)
{
    Set-Location $deploymentFolderPath

    #Check for SQLServer Module
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

    #needed for git integration
    az extension add --upgrade --name datafactory

    #accept custom image terms
    #https://docs.microsoft.com/en-us/cli/azure/vm/image/terms?view=azure-cli-latest

    #az vm image terms accept --urn h2o-ai:h2o-driverles-ai:h2o-dai-lts:latest



    if ($gitDeploy)
    {
        $resourceGroupName = [System.Environment]::GetEnvironmentVariable('ARM_RESOURCE_GROUP_NAME')
        $synapseWorkspaceName = [System.Environment]::GetEnvironmentVariable('ARM_RESOURCE_SYNAPSE_WORKSPACE_NAME')
        $env:TF_VAR_ip_address = (Invoke-WebRequest ifconfig.me/ip).Content 
    }
    else
    {
    
        #Only Prompt if Environment Variable has not been set
        if ($null -eq [System.Environment]::GetEnvironmentVariable('environmentName'))
        {        
            $envlist = (Get-ChildItem -Directory -Path ./environments/vars | Select-Object -Property Name).Name
            Import-Module ./pwshmodules/GetSelectionFromUser.psm1 -Force   
            $environmentName = Get-SelectionFromUser -Options ($envlist) -Prompt "Select deployment environment"
            [System.Environment]::SetEnvironmentVariable('environmentName', $environmentName)
        }

        $env:TF_VAR_ip_address2 = (Invoke-WebRequest ifconfig.me/ip).Content     

    }



    $environmentName = [System.Environment]::GetEnvironmentVariable('environmentName')

    if ($environmentName -eq "Quit" -or [string]::IsNullOrEmpty($environmentName))
    {
        write-host "environmentName is currently: $environmentName"
        Write-Error "Environment is not set"
        Exit
    }


    #Re-process Environment Config Files. 
    Set-Location ./environments/vars/
    ./PreprocessEnvironment.ps1 -Environment $environmentName -FeatureTemplate $FeatureTemplate -gitDeploy $gitDeploy
    Set-Location $deploymentFolderPath

    [System.Environment]::SetEnvironmentVariable('TFenvironmentName',$environmentName)

    try
    {
        $hiddenoutput = az keyvault network-rule add -g $env:TF_VAR_resource_group_name --name $env:keyVaultName --ip-address $env:TF_VAR_ip_address/32
        $hiddenoutput = az synapse workspace firewall-rule create --name AllowCICD --resource-group $env:TF_VAR_resource_group_name --start-ip-address $env:TF_VAR_ip_address --end-ip-address $env:TF_VAR_ip_address --workspace-name $env:ARM_SYNAPSE_WORKSPACE_NAME
        $hiddenoutput = az storage account network-rule add --resource-group $env:TF_VAR_resource_group_name --account-name $env:datalakeName --ip-address $env:TF_VAR_ip_address
    }
    catch
    {
        Write-Warning 'Opening Firewalls for IP Address One Failed'
    }

    try
    {
        $hiddenoutput = az keyvault network-rule add -g $env:TF_VAR_resource_group_name --name $env:keyVaultName --ip-address $env:TF_VAR_ip_address2/32
        $hiddenoutput = az synapse workspace firewall-rule create --name AllowCICD --resource-group $env:TF_VAR_resource_group_name --start-ip-address $env:TF_VAR_ip_address2 --end-ip-address $env:TF_VAR_ip_address2 --workspace-name $env:ARM_SYNAPSE_WORKSPACE_NAME
        $hiddenoutput = az storage account network-rule add --resource-group $env:TF_VAR_resource_group_name --account-name $env:datalakeName --ip-address $env:TF_VAR_ip_address2
    }
    catch
    {
        Write-Warning 'Opening Firewalls for IP Address Two Failed'
    }

    if([string]::IsNullOrEmpty($PathToReturnTo) -ne $true)
    {
        Write-Debug "Returning to $PathToReturnTo"
        Set-Location $PathToReturnTo
    }
    else {
        Write-Debug "Path to return to is null"
    }

}