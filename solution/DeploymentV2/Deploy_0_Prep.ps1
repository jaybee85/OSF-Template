$gitDeploy = ([System.Environment]::GetEnvironmentVariable('gitDeploy')  -eq 'true')

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
    $specificuser = [System.Environment]::GetEnvironmentVariable('specificUserIdForWebAppAdmin')
    if ($specificuser -ne "") {
        $AddSpecificUserAsWebAppAdmin = $true        
    } else {
        $AddSpecificUserAsWebAppAdmin = $false
    }
    $env:AdsGf_AddSpecificUserAsWebAppAdmin = $AddSpecificUserAsWebAppAdmin 

}
else
{
    function Get-SelectionFromUser {
        param (
            [Parameter(Mandatory=$true)]
            [string[]]$Options,
            [Parameter(Mandatory=$true)]
            [string]$Prompt        
        )
        
        [int]$Response = 0;
        [bool]$ValidResponse = $false    
    
        while (!($ValidResponse)) {            
            [int]$OptionNo = 0
    
            Write-Host $Prompt -ForegroundColor DarkYellow
            Write-Host "[0]: Quit"
    
            foreach ($Option in $Options) {
                $OptionNo += 1
                Write-Host ("[$OptionNo]: {0}" -f $Option)
            }
    
            if ([Int]::TryParse((Read-Host), [ref]$Response)) {
                if ($Response -eq 0) {
                    return ''
                }
                elseif($Response -le $OptionNo) {
                    $ValidResponse = $true
                }
            }
        }
    
        return $Options.Get($Response - 1)
    } 
    
    #Only Prompt if Environment Variable has not been set
    if ($null -eq [System.Environment]::GetEnvironmentVariable('environmentName'))
    {
        $environmentName = Get-SelectionFromUser -Options ('local','staging', 'admz') -Prompt "Select deployment environment"
        [System.Environment]::SetEnvironmentVariable('environmentName', $environmentName)
    }
}



$environmentName = [System.Environment]::GetEnvironmentVariable('environmentName')

$skipTerraformDeployment = ([System.Environment]::GetEnvironmentVariable('skipTerraformDeployment')  -eq 'true')
if ($environmentName -eq "Quit" -or [string]::IsNullOrEmpty($environmentName))
{
    write-host "environmentName is currently: $environmentName"
    Write-Error "Environment is not set"
    Exit
}


[System.Environment]::SetEnvironmentVariable('TFenvironmentName',$environmentName)




