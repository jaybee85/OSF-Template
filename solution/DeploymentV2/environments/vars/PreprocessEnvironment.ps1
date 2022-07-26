<# 

This script processes common_vars_values.jsonc in the selected folder 

#>
param (
    [Parameter(Mandatory=$true)]
    [string]$Environment="staging",
    [Parameter(Mandatory=$true)]
    [string]$FeatureTemplate="basic_deployment",
    [Parameter(Mandatory=$false)]
    [bool]$gitDeploy=$false
)

$Environment = $Environment.ToLower()

#First Convert Terraform Commons to YAML
#Install-Module powershell-yaml -Force
$GithubEnvTemplate = ""

Write-Host "Preparing Environment: $Environment Using $FeatureTemplate Template"

(jsonnet "./common_vars_template.jsonnet" --tla-str featuretemplatename=$FeatureTemplate --tla-str environment=$Environment  ) | Set-Content("./$Environment/common_vars.json")
$obj = Get-Content ./$Environment/common_vars.json | ConvertFrom-Json

foreach($t in ($obj.ForEnvVar | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"}))
{
    $Name = $t.Name
    $Value = $obj.ForEnvVar[0].$Name
    if($Value.GetType().Name -eq "Boolean")
    {
        $Value = $Value.ToString().ToLower()
    }           
        
    if([string]::IsNullOrEmpty($Value) -eq $false -and $Value -ne '#####')
    {          
        [Environment]::SetEnvironmentVariable($Name, $Value) 
    }      
}

foreach($t in ($obj.ForSecretFile | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"}))
{
    $Name = $t.Name
    $Value = $obj.ForSecretFile[0].$Name
    #Add to GitHubSecretFile
    $GithubEnvTemplate = $GithubEnvTemplate + "$Name=$Value" + [System.Environment]::NewLine
}

#Write the Terraform Element common_vars_for_hcl.json - this is then injected into the hcl file
($obj.ForHCL | ConvertTo-Json -Depth 10) | Set-Content ./$Environment/common_vars_for_hcl.json 

if($gitDeploy -eq $false)
{
    #Write the Git Secrets to the Git Template .env
    $GithubEnvTemplate|Set-Content ./$Environment/GetSecretsTemplate.env
}