remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    # You need to update the resource group and storage account here. 
    # You should have created these with the Prepare.ps1 script.
    resource_group_name  = "AdsGoFastDemo"
    storage_account_name = "TerraformStateAccount"
    container_name       = "tstate"
    key                  = "terraform.tfstate"
  }
}

# These inputs are provided to the terraform variables when deploying the environment
# If you are deploying using pipelines, these can be overridden from environment variables
# using TF_VAR_variablename
inputs = {
  prefix                                = "ads"              # All azure resources will be prefixed with this
  domain                                = "contoso.com"              # Used when configuring AAD config for Azure functions 
  tenant_id                             = "63a6ed72-a904-4f18-95dd-3b4c9ffdd1d1"           # This is the Azure AD tenant ID
  subscription_id                       = "c5743ec2-31b2-4596-baaf-779cd189bb94"     # The azure subscription id to deploy to
  resource_location                     = "Australia East"        # The location of the resources
  resource_group_name                   = "AdsGoFastDemo"          # The resource group all resources will be deployed to
  owner_tag                             = "Contoso"               # Owner tag value for Azure resources
  environment_tag                       = "stg"                   # This is used on Azure tags as well as all resource names
  ip_address                            = "192.168.0.1"          # This is the ip address of the agent/current IP. Used to create firewall exemptions.
  deploy_sentinel                       = true
  deploy_purview                        = true      
  deploy_synapse                        = true
  is_vnet_isolated                      = true
  publish_web_app                       = true
  publish_function_app                  = true
  publish_sample_files                  = true
  publish_database                      = true
  configure_networking                  = true
  publish_datafactory_pipelines         = true
  publish_web_app_addcurrentuserasadmin = true
  deploy_selfhostedsql                  = false
  is_onprem_datafactory_ir_registered   = false
} 
