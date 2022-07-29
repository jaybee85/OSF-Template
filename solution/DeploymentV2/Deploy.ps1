#----------------------------------------------------------------------------------------------------------------
# You must be logged into the Azure CLI to run this script
#----------------------------------------------------------------------------------------------------------------
# This script will:
# - Deploy all infra resources using terra
# - Approve all private link requests
# - Build and deploy web app
# - Build and deploy function app
# - Build database app and deploy
# - Deploy samples into blob storage
# 
# This is intended for creating a once off deployment from your development machine. You should setup the
# GitHub actions for your long term prod/non-prod environments
#
# Intructions
# - Ensure that you have run the Prepare.ps1 script first. This will prepare your azure subscription for deployment
# - Ensure that you have run az login and az account set
# - Ensure you have Owner access to the resource group you are planning on deploying to
# - Run this script
# 
# You can run this script multiple times if needed.
# 
# ./Deploy.ps1 -RunTerraformLayer1 $true -FeatureTemplate "basic_deployment" -PerformPostIACPublishing $false          
# ./Deploy.ps1 -RunTerraformLayer2 $true -FeatureTemplate "basic_deployment" -PerformPostIACPublishing $true
# ./Deploy.ps1 -RunTerraformLayer3 $true -FeatureTemplate "basic_deployment" -$PublishSQLLogins $true
# 
#----------------------------------------------------------------------------------------------------------------
param (
    [Parameter(Mandatory=$false)]
    [bool]$RunTerraformLayer1=0,
    [Parameter(Mandatory=$false)]
    [bool]$RunTerraformLayer2=0,
    [Parameter(Mandatory=$false)]
    [bool]$RunTerraformLayer3=0,
    [Parameter(Mandatory=$false)]
    [bool]$PublishMetadataDatabase=$true,
    [Parameter(Mandatory=$false)]
    [bool]$PublishSQLLogins=0,
    [Parameter(Mandatory=$false)]
    [bool]$PerformPostIACPublishing=0,    
    [Parameter(Mandatory=$false)]
    [string]$FeatureTemplate="basic_deployment"

)

#------------------------------------------------------------------------------------------------------------
# Module Imports #Mandatory
#------------------------------------------------------------------------------------------------------------
import-Module ./pwshmodules/GatherOutputsFromTerraform.psm1 -force
import-Module ./pwshmodules/Deploy_0_Prep.psm1 -force
#------------------------------------------------------------------------------------------------------------
# Preparation #Mandatory
#------------------------------------------------------------------------------------------------------------
$deploymentFolderPath = (Get-Location).Path 
$gitDeploy = ([System.Environment]::GetEnvironmentVariable('gitDeploy')  -eq 'true')
$skipTerraformDeployment = ([System.Environment]::GetEnvironmentVariable('skipTerraformDeployment')  -eq 'true')
$ipaddress = $env:TF_VAR_ip_address
$ipaddress2 = $env:TF_VAR_ip_address2

PrepareDeployment -gitDeploy $gitDeploy -deploymentFolderPath $deploymentFolderPath -FeatureTemplate $FeatureTemplate

#------------------------------------------------------------------------------------------------------------
# Main Terraform
#------------------------------------------------------------------------------------------------------------
./Deploy_1_Infra0.ps1 -RunTerraformLayer1 $RunTerraformLayer1 -RunTerraformLayer2 $RunTerraformLayer2 -RunTerraformLayer3 $RunTerraformLayer3 -skipTerraformDeployment $skipTerraformDeployment


#------------------------------------------------------------------------------------------------------------
# Get all the outputs from terraform so we can use them in subsequent steps #Mandatory
#------------------------------------------------------------------------------------------------------------
Set-Location "./terraform_layer2"
Write-Host "Reading Terraform Outputs"
#Run Init Just in Case we skipped the Infra Section
#$init = terragrunt init --terragrunt-config vars/$environmentName/terragrunt.hcl -reconfigure
$tout = GatherOutputsFromTerraform -TerraformFolderPath "./"
$outputs = terragrunt output -json --terragrunt-config ./vars/$env:environmentName/terragrunt.hcl | ConvertFrom-Json
$subscription_id =$outputs.subscription_id.value
$resource_group_name =$outputs.resource_group_name.value
$webapp_name =$outputs.webapp_name.value
$functionapp_name=$outputs.functionapp_name.value
$purview_name=$outputs.purview_name.value
$sqlserver_name=$outputs.sqlserver_name.value
$blobstorage_name=$outputs.blobstorage_name.value
$adlsstorage_name=$outputs.adlsstorage_name.value
$datafactory_name=$outputs.datafactory_name.value
$keyvault_name=$outputs.keyvault_name.value
#sif database name
$sifdb_name  = if([string]::IsNullOrEmpty($outputs.sifdb_name.value)){"SIFDM"}
$stagingdb_name=$outputs.stagingdb_name.value
$sampledb_name=$outputs.sampledb_name.value
$metadatadb_name=$outputs.metadatadb_name.value
$loganalyticsworkspace_id=$outputs.loganalyticsworkspace_id.value
$purview_sp_name=$outputs.purview_sp_name.value
$synapse_workspace_name=if([string]::IsNullOrEmpty($outputs.synapse_workspace_name.value)) {"Dummy"} else {$outputs.synapse_workspace_name.value}
$synapse_sql_pool_name=if([string]::IsNullOrEmpty($outputs.synapse_sql_pool_name.value)) {"Dummy"} else {$outputs.synapse_sql_pool_name.value}
$synapse_spark_pool_name=if([string]::IsNullOrEmpty($outputs.synapse_spark_pool_name.value)) {"Dummy"} else {$outputs.synapse_spark_pool_name.value}
$skipCustomTerraform = if($tout.deploy_custom_terraform) {$false} else {$true}
$skipWebApp = if($tout.publish_web_app -and $tout.deploy_web_app) {$false} else {$true}
$skipFunctionApp = if($tout.publish_function_app -and $tout.deploy_function_app) {$false} else {$true}
$skipDatabase = if($tout.publish_metadata_database -and $tout.deploy_metadata_database) {$false} else {$true}
$skipSQLLogins = if($tout.publish_sql_logins -and $tout.deploy_sql_server) {$false} else {$true}
$skipSynapseLogins = if($tout.publish_sql_logins -and $tout.deploy_synapse) {$false} else {$true}
$skipSampleFiles = if($tout.publish_sample_files){$false} else {$true}
$skipSIF= if($tout.publish_sif_database){$false} else {$true}
$skipNetworking = if($tout.configure_networking){$false} else {$true}
$skipDataFactoryPipelines = if($tout.publish_datafactory_pipelines) {$false} else {$true}
$skipFunctionalTests = if($tout.publish_functional_tests) {$false} else {$true}
$skipConfigurePurview = if($tout.publish_configure_purview) {$false} else {$true}
$AddCurrentUserAsWebAppAdmin = if($tout.publish_web_app_addcurrentuserasadmin) {$true} else {$false}
Set-Location $deploymentFolderPath


#------------------------------------------------------------------------------------------------------------
# Run Each SubModule
#------------------------------------------------------------------------------------------------------------
./Deploy_3_Infra1.ps1 -deploymentFolderPath $deploymentFolderPath -skipTerraformDeployment $skipTerraformDeployment -skipCustomTerraform $skipCustomTerraform

#------------------------------------------------------------------------------------------------------------
# SQL Deployment and Users 
# In order for a deployment agent service principal to execute the two scripts below you need to give directory read to the Azure SQL Instance Managed Identity and the Synapse Managed Identity
#------------------------------------------------------------------------------------------------------------
./Deploy_8_SQLLogins.ps1 -PublishSQLLogins $PublishSQLLogins

#------------------------------------------------------------------------------------------------------------
# Data Factory & Synapse  Artefacts and Samplefiles 
#------------------------------------------------------------------------------------------------------------

if($PerformPostIACPublishing -eq $false) {
    Write-Host "Skipping Post IAC Publishing"
}
else {
    ./Deploy_4_PrivateLinks.ps1
    ./Deploy_5_WebApp.ps1
    ./Deploy_6_FuncApp.ps1
    ./Deploy_7_MetadataDB.ps1 -publish_metadata_database $PublishMetadataDatabase
    ./Deploy_9_DataFactory.ps1
    ./Deploy_10_SampleFiles.ps1
}


#----------------------------------------------------------------------------------------------------------------
#   Set up Purview
#----------------------------------------------------------------------------------------------------------------
# This is a WIP - not recommended to use for standard user
#----------------------------------------------------------------------------------------------------------------
#
if($skipConfigurePurview) {
    Write-Host "Skipping experimental Purview Configuration"
}
else {
    Write-Host "Running Purview Configuration (experimental) Script"
    Set-Location $deploymentFolderPath
    Invoke-Expression ./ConfigureAzurePurview.ps1
}


#----------------------------------------------------------------------------------------------------------------
#   Deploy Functional Tests
#----------------------------------------------------------------------------------------------------------------
# This is for development purposes primarily - If using, understand these may not be all working with most recent platform version as tests can become outdated / missing new required fields.
#----------------------------------------------------------------------------------------------------------------
if($skipFunctionalTests) {
    Write-Host "Skipping Functional Tests Upload"
}
else {
    Write-Host "Deploying Functional Tests to Web App"
    Set-Location $deploymentFolderPath
    Invoke-Expression ./GenerateAndUploadFunctionalTests.ps1
}



Set-Location $deploymentFolderPath
Write-Host "Finished"