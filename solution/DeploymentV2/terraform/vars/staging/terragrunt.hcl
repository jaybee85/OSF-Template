
remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    resource_group_name  = "ark-stg-rg-ads"
    storage_account_name = "arkstgstadsstate"
    container_name       = "tstate"
    key                  = "terraform.tfstate"
  }
}

# These inputs are provided to the terraform variables when deploying the environment
# If you are deploying using pipelines, these can be overridden from environment variables
# using TF_VAR_variablename

inputs = {
  prefix                                = "ark"
  domain                                = "arkahna.io"  
  tenant_id                             = "0fee3d31-b963-4a1c-8f4a-ca367205aa65"
  subscription_id                       = "03a36be0-8f6a-4436-a9f5-499ba3c77823"
  resource_location                     = "Australia East"
  resource_group_name                   = "ark-stg-rg-ads"
  owner_tag                             = "arkahna.io"
  environment_tag                       = "stg"  
  ip_address                            = "203.123.100.64"
  deploy_sentinel                       = true
  deploy_purview                        = false      
  deploy_synapse                        = true
}
