
#------------------------------------------------------------------------------------------------------------
# Deploy the customisable terraform layer
#------------------------------------------------------------------------------------------------------------
if ($skipCustomTerraform) {
    Write-Host "Skipping Custom Terraform Layer"    
}
else {
    Set-Location $deploymentFolderPath
    Set-Location "./terraform_custom"

    terragrunt init --terragrunt-config vars/$environmentName/terragrunt.hcl -reconfigure

    if ($skipTerraformDeployment) {
        Write-Host "Skipping Custom Terraform Deployment"
    }
    else {
        Write-Host "Starting Custom Terraform Deployment"
        terragrunt apply -auto-approve --terragrunt-config vars/$environmentName/terragrunt.hcl
    }
}
#------------------------------------------------------------------------------------------------------------
$deploymentFolderPath = (Get-Location).Path