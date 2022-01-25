remote_state = {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    # You need to update the resource group and storage account here. 
    # You should have created these with the Prepare.ps1 script.
    resource_group_name  = "adsgftera2"
    storage_account_name = "adsgftera2state"
    container_name       = "tstate"
    key                  = "terraform.tfstate"
  }
}

inputs = {
  prefix                                = "mst"
  domain                                = "microsoft.com"
  tenant_id                             = "72f988bf-86f1-41af-91ab-2d7cd011db47"
  subscription_id                       = "035a1364-f00d-48e2-b582-4fe125905ee3"
  resource_location                     = "Australia East"
  resource_group_name                   = "adsgftera2"
  owner_tag                             = "microsoft"
  environment_tag                       = "stg"  
  ip_address                            = "144.138.148.220"
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
} 


