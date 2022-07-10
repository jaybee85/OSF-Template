#------------------------------------------------------------------------------------------------------------
# Get all the outputs from terraform so we can use them in subsequent steps
#------------------------------------------------------------------------------------------------------------
Set-Location "./terraform"
Write-Host "Reading Terraform Outputs"
Import-Module .\..\GatherOutputsFromTerraform.psm1 -force
$tout = GatherOutputsFromTerraform

$outputs = terragrunt output -json --terragrunt-config ./vars/$environmentName/terragrunt.hcl | ConvertFrom-Json

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