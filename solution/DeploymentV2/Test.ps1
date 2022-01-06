#----------------------------------------------------------------------------------------------------------------
# You must be logged into the Azure CLI to run this script
#----------------------------------------------------------------------------------------------------------------
# This script will:
# TBA
# 
# You can run this script multiple times if needed.
#----------------------------------------------------------------------------------------------------------------

$environmentName = "local" # currently supports (local, staging)
$myIp = (Invoke-WebRequest ifconfig.me/ip).Content

$deploymentFolderPath = $PWD
Set-Location ".\terraform"
$env:TF_VAR_ip_address = $myIp

#------------------------------------------------------------------------------------------------------------
# Get all the outputs from terraform so we can use them in subsequent steps
#------------------------------------------------------------------------------------------------------------
Write-Host "Reading Terraform Outputs"
$tout = terraform output -json | ConvertFrom-Json


Set-Location $deploymentFolderPath
Write-Host "Finished"