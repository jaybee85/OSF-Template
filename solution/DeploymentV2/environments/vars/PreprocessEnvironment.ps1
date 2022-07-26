<# 

This script processes common_vars_values.jsonc in the selected folder 

#>
param (
    [Parameter(Mandatory=$true)]
    [string]$Environment="staging",
    [Parameter(Mandatory=$true)]
    [string]$FeatureTemplate="full_deployment",
    [Parameter(Mandatory=$false)]
    [bool]$gitDeploy=$false
)

$Environment = $Environment.ToLower()

#First Convert Terraform Commons to YAML
Install-Module powershell-yaml -Force
$GithubEnvTemplate = ""

Write-Host "Preparing Environment: $Environment"

(jsonnet "./common_vars_template.jsonnet" --tla-str featuretemplatename=$FeatureTemplate --tla-str environment=$Environment  ) | Set-Content("./$Environment/common_vars.json")
$obj = Get-Content ./$Environment/common_vars.json | ConvertFrom-Json
$HCLYaml = @{}
foreach($t in $obj.Variables)
{
    $Value = $t.Value    
    if($t.EnvVarName -ne "")
    {
        $Name = $t.EnvVarName
        if([string]::IsNullOrEmpty($Value) -eq $false -and $Value -ne '#####')
        {
            [Environment]::SetEnvironmentVariable($Name, "$Value") 
        }
    }        

    if($t.CICDSecretName -ne "")
    {
        $Name = $t.CICDSecretName
        #Add to GitHubSecretFile
        $GithubEnvTemplate = $GithubEnvTemplate + "$Name=$Value" + [System.Environment]::NewLine
    }

    if($t.HCLName -ne "")
    {
       $Name = $t.HCLName
       #Add to CommonVars.yaml       
       $HCLYAML.$Name = $Value       
    }

}

#Write the Terraform Element common_vars.yaml - this is then injected into the hcl file
$HCLYAML | ConvertTo-YAML | Set-Content ./$Environment/common_vars.yaml

if($gitDeploy -eq $false)
{
    #Write the Git Secrets to the Git Template .env
    $GithubEnvTemplate|Set-Content ./$Environment/GetSecretsTemplate.env
}