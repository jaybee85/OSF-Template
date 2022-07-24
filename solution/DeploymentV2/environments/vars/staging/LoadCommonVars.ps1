
#First Convert Terraform Commons to YAML
Install-Module powershell-yaml -Force
$obj = Get-Content ./common_vars.json | ConvertFrom-Json
$obj.Teraform | ConvertTo-YAML | Set-Content ./common_vars.yaml

#Next Convert Environment to Environment Variables
$envars = $obj.Environment

foreach($e in $envars)
{
    $Name = ($e | get-member)[-1].Name
    [Environment]::SetEnvironmentVariable($Name, "$Value")
}