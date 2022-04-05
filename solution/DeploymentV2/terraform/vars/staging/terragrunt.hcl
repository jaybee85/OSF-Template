remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    # You need to update the resource group and storage account here. 
    # You should have created these with the Prepare.ps1 script.
    resource_group_name  = "wap-rg-dev-ae-data-001"
    storage_account_name = "wapstgdevaedata002"
    container_name       = "tstate"
    key                  = "terraform.tfstate"
  }
}

# These inputs are provided to the terraform variables when deploying the environment
# If you are deploying using pipelines, these can be overridden from environment variables
# using TF_VAR_variablename
inputs = {
  prefix                                = "wap"              # All azure resources will be prefixed with this
  domain                                = "wapha.org.au"              # Used when configuring AAD config for Azure functions 
  tenant_id                             = "475172ff-50d6-420a-998e-9294dfbf1596"           # This is the Azure AD tenant ID
  subscription_id                       = "560d02d4-8801-41bc-be33-09fb7930ad0d"     # The azure subscription id to deploy to
  resource_location                     = "Australia East"        # The location of the resources
  resource_group_name                   = "wap-rg-dev-ae-data-001"          # The resource group all resources will be deployed to
  owner_tag                             = "WAPHA"               # Owner tag value for Azure resources
  environment_tag                       = "dev"                   # This is used on Azure tags as well as all resource names
  ip_address                            = "14.201.191.172"          # This is the ip address of the agent/current IP. Used to create firewall exemptions.
  deploy_sentinel                       = false
  deploy_purview                        = false      
  deploy_synapse                        = true
  is_vnet_isolated                      = true
  publish_web_app                       = true
  publish_function_app                  = true
  publish_sample_files                  = true
  publish_database                      = true
  configure_networking                  = true
  publish_datafactory_pipelines         = true
  publish_web_app_addcurrentuserasadmin = true
  deploy_selfhostedsql                  = true
  is_onprem_datafactory_ir_registered   = true
  logs_storage_account_name             = "wapstgdevaedata005"
  adls_storage_account_name             = "wapstgdevaedata003"
  blob_storage_account_name             = "wapstgdevaedata004"
  bastion_name                          = "wap-bst-dev-ae-data-001"
  key_vault_name                        = "wap-kv-dev-ae-data-002"
} 
