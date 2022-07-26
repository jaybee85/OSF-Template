param (
    [Parameter(Mandatory=$false)]
    [System.Boolean]$skipTerraformDeployment=$true,
    [Parameter(Mandatory=$false)]
    [System.Boolean]$RunTerraformLayer1=$false,
    [Parameter(Mandatory=$false)]
    [System.Boolean]$RunTerraformLayer2=$false,
    [Parameter(Mandatory=$false)]
    [System.Boolean]$RunTerraformLayer3=$false
)

#----------------------------------------------------------------------------------------------------------------
#   Deploy Infrastructure
#----------------------------------------------------------------------------------------------------------------
# DEBUGGING HINTS:
# - If you don't have an access policy for the KeyVault to set the secret values, run this
#           az keyvault set-policy -n {keyVaultName} --secret-permissions all --object-id <<object-id-for-your-user>>
# - If the firewall is blocking you, add your IP as firewall rule / exemption to the appropriate resource
# - If you havn't run prepare but want to run this script on its own, set the TF_VAR_jumphost_password and TF_VAR_domain env vars
#------------------------------------------------------------------------------------------------------------

Set-Location "./terraform_layer1"

terragrunt init --terragrunt-config vars/$env:environmentName/terragrunt.hcl -reconfigure

if ($skipTerraformDeployment -or $RunTerraformLayer1 -ne $true) {
    Write-Host "Skipping Terraform Deployment - Layer 1"
}
else {
    Write-Host "Starting Terraform Deployment- Layer 1"
    terragrunt apply -auto-approve --terragrunt-config vars/$env:environmentName/terragrunt.hcl
}

Set-Location $deploymentFolderPath

Set-Location "./terraform_layer2"

terragrunt init --terragrunt-config vars/$env:environmentName/terragrunt.hcl -reconfigure

if ($skipTerraformDeployment -or $RunTerraformLayer2 -ne $true) {
    Write-Host "Skipping Terraform Deployment- Layer 2"
}
else {
    Write-Host "Starting Terraform Deployment- Layer 2"
    terragrunt apply -auto-approve --terragrunt-config vars/$env:environmentName/terragrunt.hcl
}

Set-Location $deploymentFolderPath

Set-Location "./terraform_layer3"

terragrunt init --terragrunt-config vars/$env:environmentName/terragrunt.hcl -reconfigure

if ($skipTerraformDeployment -or $RunTerraformLayer3 -ne $true) {
    Write-Host "Skipping Terraform Deployment- Layer 3"
}
else {
    Write-Host "Starting Terraform Deployment- Layer 3"
    terragrunt apply -auto-approve --terragrunt-config vars/$env:environmentName/terragrunt.hcl
}

Set-Location $deploymentFolderPath

