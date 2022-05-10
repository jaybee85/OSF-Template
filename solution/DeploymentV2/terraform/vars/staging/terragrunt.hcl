remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    # You need to update the resource group and storage account here. 
    # You should have created these with the Prepare.ps1 script.
    resource_group_name  = "dlzdev07"
    storage_account_name = "dlzdev07state"
    container_name       = "tstate"
    key                  = "terraform.tfstate"
  }
}

# These inputs are provided to the terraform variables when deploying the environment
# If you are deploying using pipelines, these can be overridden from environment variables
# using TF_VAR_variablename
inputs = {
  prefix                                = "ark"              # All azure resources will be prefixed with this
  domain                                = "arkahna.io"              # Used when configuring AAD config for Azure functions 
  tenant_id                             = "0fee3d31-b963-4a1c-8f4a-ca367205aa65"           # This is the Azure AD tenant ID
  subscription_id                       = "63cbc080-0220-46aa-a9c4-a50b36f1ff43"     # The azure subscription id to deploy to
  resource_location                     = "Australia East"        # The location of the resources
  resource_group_name                   = "dlzdev07"          # The resource group all resources will be deployed to
  owner_tag                             = "Arkahna"               # Owner tag value for Azure resources
  environment_tag                       = "stg"                   # This is used on Azure tags as well as all resource names
  ip_address                            = "60.227.74.75"          # This is the ip address of the agent/current IP. Used to create firewall exemptions.
  deploy_sentinel                       = false
  deploy_purview                        = false  
  deploy_synapse                        = true
  is_vnet_isolated                      = false
  publish_web_app                       = true
  publish_function_app                  = true
  publish_sample_files                  = true
  publish_database                      = true
  configure_networking                  = false
  publish_datafactory_pipelines         = true
  publish_web_app_addcurrentuserasadmin = true
  deploy_synapse_sqlpool                = false
  deploy_selfhostedsql                  = false
  is_onprem_datafactory_ir_registered   = false

  purview_name = "dlzdev07purv"

  synapse_git_toggle_integration = true
  synapse_git_integration_type = "devops"
  synapse_git_repository_owner = "hugosharpe"
  synapse_git_repository_name = "lockBoxProject"
 // NOT USED - synapse_git_repository_base_url = "https://dev.azure.com/hugosharpe/_git/lockBoxProject"
  synapse_git_repository_branch_name = "dlzdev07"
  synapse_git_repository_root_folder = "/Synapse"
  synapse_git_devops_project_name = "lockBoxProject"
  synapse_git_use_pat = true
  synapse_git_pat = "iukwy7dntnpicwndxq4g3xcni355i2gxitm4pcushzgbsxon5x3q"

  /*synapse_git_toggle_integration = true
  synapse_git_repository_owner = "h-sha"
  synapse_git_repository_name = "testLockbox"
  synapse_git_repository_branch_name = "dlz07Test"
  synapse_git_repository_root_folder = "/Synapse"
  synapse_git_use_pat = false
  synapse_git_pat = "iukwy7dntnpicwndxq4g3xcni355i2gxitm4pcushzgbsxon5x3q"*/

  adf_git_toggle_integration = true
  adf_git_repository_owner = "h-sha"
  adf_git_repository_name = "testLockbox"
  adf_git_repository_branch_name = "dlz07Test"
  adf_git_repository_root_folder = "/ADF"
  adf_git_use_pat = false
  adf_git_pat = "iukwy7dntnpicwndxq4g3xcni355i2gxitm4pcushzgbsxon5x3q"
} 
