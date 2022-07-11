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
  configure_networking                  = false
  is_vnet_isolated                      = true
  publish_web_app                       = false
  publish_function_app                  = false
  publish_sample_files                  = true
  publish_metadata_database             = false
  publish_datafactory_pipelines         = true
  publish_web_app_addcurrentuserasadmin = true
  deploy_web_app                        = false
  deploy_function_app                   = false
  deploy_custom_terraform               = false # This is whether the infrastructure located in the terraform_custom folder is deployed or not.
  deploy_bastion                        = false
  deploy_sentinel                       = false
  deploy_purview                        = false  
  deploy_synapse                        = true  
  deploy_app_service_plan               = false
  deploy_synapse_sqlpool                = false
  deploy_selfhostedsql                  = false
  deploy_metadata_database              = false
  deploy_h2o-ai                         = false
  is_onprem_datafactory_ir_registered   = false
  publish_sif_database                  = {publish_sif_database}

  #Below is a space for providing details of EXISTING resources so that the deployment can integrate with your management zone.
  #Please ensure that you enter everything that is relevant otherwise deployed resources may not work properly.
  
  #log anayltics resource id can be found under the properties of the log analytics resource NOTE: This is the full URI not the workspaceID
  existing_log_analytics_resource_id    = "LOG ANALYTICS RESOURCE ID"
  existing_log_analytics_workspace_id   = "LOG ANALYTICS WORKSPACE ID"
  #synapse private link hub id can be found under the properties of the synapse private link NOTE: This is the full URI (ResourceID)
  existing_synapse_private_link_hub_id  = "SYNAPSE PRIVATE LINK HUB ID"

  #Please assign subnet id's for the following - you may end up using the same subnet id for all of these resources depending on your already deployed assets.
    #command used to get subnet ids:
  # az network vnet subnet show -g MyResourceGroup -n MySubnet --vnet-name MyVNet
  existing_plink_subnet_id              = "PRIVATE LINK SUBNET ID"
  existing_bastion_subnet_id            = "BASTION SUBNET ID"
  existing_app_service_subnet_id        = "APP SERVICE SUBNET ID"
  existing_vm_subnet_id                 = "VM SUBNET ID"

  #assign the private DNS zone id's for the following.
  #command used to get existing private-dns zones:
  #az network private-dns zone list -g MyResourceGroup
  existing_private_dns_zone_db_id       = "DB PRIVATE DNS ZONE ID"
  existing_private_dns_zone_kv_id       = "KEYVAULT PRIVATE DNS ZONE ID"
  existing_private_dns_zone_blob_id     = "BLOB PRIVATE DNS ZONE ID"
  existing_private_dns_zone_queue_id    = "QUEUE PRIVATE DNS ZONE ID"
  existing_private_dns_zone_dfs_id      = "DFS PRIVATE DNS ZONE ID"
  existing_private_dns_zone_purview_id  = "PURVIEW PRIVATE DNS ZONE ID"
  existing_private_dns_zone_purview_studio_id = "PURVIEW STUDIO PRIVATE DNS ZONE ID"
  existing_private_dns_zone_servicebus_id = "SERVICEBUS PRIVATE DNS ZONE ID"
  existing_private_dns_zone_synapse_gateway_id = "SYNAPSE GATEWAY PRIVATE DNS ZONE ID"
  existing_private_dns_zone_synapse_studio_id = "SYNAPSE STUDIO PRIVATE DNS ZONE ID"
  existing_private_dns_zone_synapse_sql_id = "SYNAPSE SQL PRIVATE DNS ZONE ID"

} 