

# These inputs are provided to the terraform variables when deploying the environment
# If you are deploying using pipelines, these can be overridden from environment variables
# using TF_VAR_variablename
inputs = {
  prefix                                = "ark"              # All azure resources will be prefixed with this
  domain                                = "arkahna.io"              # Used when configuring AAD config for Azure functions 
  tenant_id                             = "0fee3d31-b963-4a1c-8f4a-ca367205aa65"           # This is the Azure AD tenant ID
  subscription_id                       = "14f299e1-be54-43e9-bf5e-696840f86fc4"     # The azure subscription id to deploy to
  resource_location                     = "Australia East"        # The location of the resources
  resource_group_name                   = "dlzdev08lite"          # The resource group all resources will be deployed to
  owner_tag                             = "Arkahna"               # Owner tag value for Azure resources
  environment_tag                       = "prod"                   # This is used on Azure tags as well as all resource names
  ip_address                            = "101.179.193.89"          # This is the ip address of the agent/current IP. Used to create firewall exemptions.
  configure_networking                  = false
  is_vnet_isolated                      = true
  publish_web_app                       = false
  publish_function_app                  = false
  publish_sample_files                  = true
  publish_database                      = false
  publish_datafactory_pipelines         = true
  publish_web_app_addcurrentuserasadmin = true
  deploy_bastion                        = false
  deploy_sentinel                       = false
  deploy_purview                        = false  
  deploy_synapse                        = true  
  deploy_app_service_plan               = false
  deploy_synapse_sqlpool                = false
  deploy_selfhostedsql                  = false
  deploy_h2o-ai                         = false
  is_onprem_datafactory_ir_registered   = false

  #Below is a space for providing details of EXISTING resources so that the deployment can integrate with your management zone.
  #Please ensure that you enter everything that is relevant otherwise deployed resources may not work properly.
  existing_log_analytics_workspace_id   = "LOG ANALYTICS WORKSPACE ID"
  existing_synapse_private_link_hub_id  = "SYNAPSE PRIVATE LINK HUB ID"

  #Please assign subnet id's for the following - you may end up using the same subnet id for all of these resources depending on your already deployed assets.
  existing_plink_subnet_id              = "PRIVATE LINK SUBNET ID"
  existing_bastion_subnet_id            = "BASTION SUBNET ID"
  existing_app_service_subnet_id        = "APP SERVICE SUBNET ID"
  existing_vm_subnet_id                 = "VM SUBNET ID"

  #assign the private DNS zone id's for the following.

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
