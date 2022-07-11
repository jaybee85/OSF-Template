remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    # You need to update the resource group and storage account here. 
    # You should have created these with the Prepare.ps1 script.
    resource_group_name  = "{resource_group_name}"
    storage_account_name = "{storage_account_name}"
    container_name       = "tstate"
    key                  = "terraform.tfstate"
  }
}

# These inputs are provided to the terraform variables when deploying the environment
# If you are deploying using pipelines, these can be overridden from environment variables
# using TF_VAR_variablename
inputs = {
  prefix                                = "{prefix}"              # All azure resources will be prefixed with this
  domain                                = "{domain}"              # Used when configuring AAD config for Azure functions 
  tenant_id                             = "{tenant_id}"           # This is the Azure AD tenant ID
  subscription_id                       = "{subscription_id}"     # The azure subscription id to deploy to
  resource_location                     = "Australia East"        # The location of the resources
  resource_group_name                   = "{resource_group_name}"          # The resource group all resources will be deployed to
  owner_tag                             = "Contoso"               # Owner tag value for Azure resources
  environment_tag                       = "stg"                   # This is used on Azure tags as well as all resource names
  ip_address                            = "{ip_address}"          # This is the ip address of the agent/current IP. Used to create firewall exemptions.
  deploy_web_app                        = {deploy_web_app}
  deploy_function_app                   = {deploy_function_app}
  deploy_custom_terraform               = {deploy_custom_terraform} # This is whether the infrastructure located in the terraform_custom folder is deployed or not.
  deploy_app_service_plan               = {deploy_app_service_plan}
  deploy_data_factory                   = {deploy_data_factory}
  deploy_sentinel                       = {deploy_sentinel}
  deploy_purview                        = {deploy_purview}      
  deploy_synapse                        = {deploy_synapse}
  deploy_metadata_database              = {deploy_metadata_database}
  is_vnet_isolated                      = {is_vnet_isolated}
  publish_web_app                       = {publish_web_app}
  publish_function_app                  = {publish_function_app}
  publish_sample_files                  = {publish_sample_files}
  publish_metadata_database             = {publish_metadata_database}
  configure_networking                  = {configure_networking}
  publish_datafactory_pipelines         = {publish_datafactory_pipelines}
  publish_web_app_addcurrentuserasadmin = {publish_web_app_addcurrentuserasadmin}
  deploy_selfhostedsql                  = {deploy_selfhostedsql}
  is_onprem_datafactory_ir_registered   = {is_onprem_datafactory_ir_registered}
  publish_sif_database                  = {publish_sif_database}
} 