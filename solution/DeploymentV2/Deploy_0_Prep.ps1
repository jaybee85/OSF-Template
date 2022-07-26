param (
    [Parameter(Mandatory=$true)]
    [System.Boolean]$gitDeploy=$false,
    [Parameter(Mandatory=$true)]
    [String]$deploymentFolderPath,
    [Parameter(Mandatory=$true)]
    [String]$FeatureTemplate
)

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




