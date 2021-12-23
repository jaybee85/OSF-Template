resource "azurerm_storage_data_lake_gen2_filesystem" "dlfs" {
  count = var.deploy_adls && var.deploy_synapse ? 1 : 0
  name               = local.synapse_data_lake_name
  storage_account_id = azurerm_storage_account.adls[0].id
}

resource "azurerm_synapse_workspace" "synapse" {
  count = var.deploy_adls && var.deploy_synapse ? 1 : 0
  name                                 = local.synapse_workspace_name
  resource_group_name                  = var.resource_group_name
  location                             = var.resource_location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.dlfs[0].id
  sql_administrator_login              = var.synapse_sql_login
  sql_administrator_login_password     = var.synapse_sql_password
  sql_identity_control_enabled         = true
  public_network_access_enabled        = true
  managed_virtual_network_enabled      = true
  managed_resource_group_name           = local.synapse_resource_group_name
  #purview_id = azurerm_purview_account.purview.id

  tags = local.tags
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_synapse_sql_pool" "synapse_sql_pool" {
  count = var.deploy_adls && var.deploy_synapse && var.deploy_synapse_sqlpool ? 1 : 0    
  name                 = local.synapse_workspace_name
  synapse_workspace_id = azurerm_synapse_workspace.synapse[0].id
  sku_name             = var.synapse_sku
  create_mode          = "Default"
  tags = local.tags
  lifecycle {
    ignore_changes = [
      tags
    ]
  }  
}

resource "azurerm_synapse_spark_pool" "synapse_spark_pool" {
  count = var.deploy_adls && var.deploy_synapse && var.deploy_synapse_sparkpool ? 1 : 0    
  name                 = local.synapse_sppool_name
  synapse_workspace_id = azurerm_synapse_workspace.synapse[0].id
  node_size_family     = "MemoryOptimized"
  node_size            = "Small"
  cache_size           = 100

  auto_scale {
    max_node_count = var.synapse_spark_max_node_count
    min_node_count = var.synapse_spark_min_node_count
  }

  auto_pause {
    delay_in_minutes = 15
  }
  tags = local.tags
  lifecycle {
    ignore_changes = [
      tags
    ]
  }  
}

resource "azurerm_synapse_firewall_rule" "public_access" {
  count                = var.deploy_adls && var.deploy_synapse && var.allow_public_access_to_synapse_studio?1:0
  name                 = "AllowAll"
  synapse_workspace_id = azurerm_synapse_workspace.synapse[0].id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

# resource "azurerm_synapse_firewall_rule" "azure_access" {
#   count                = var.deploy_adls && var.deploy_synapse ? 1 : 0
#   name                 = "AllowAllWindowsAzureIps"
#   synapse_workspace_id = azurerm_synapse_workspace.synapse[0].id
#   start_ip_address     = "0.0.0.0"
#   end_ip_address       = "0.0.0.0"
# }


resource "azurerm_synapse_managed_private_endpoint" "adls" {
  count                = var.deploy_adls && var.deploy_synapse && var.is_vnet_isolated ? 1 : 0
  name                 = "AzureDataLake_PrivateEndpoint"
  synapse_workspace_id = azurerm_synapse_workspace.synapse[0].id
  target_resource_id   = azurerm_storage_account.adls[0].id
  subresource_name     = "dfs"
}

# // Diagnostic logs--------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "synapse_diagnostic_logs" {
  count = var.deploy_adls && var.deploy_synapse ? 1 : 0
  name                           = "diagnosticlogs"
  log_analytics_destination_type = "Dedicated"
  # ignore_changes is here given the bug  https://github.com/terraform-providers/terraform-provider-azurerm/issues/10388
  lifecycle {
    ignore_changes = [log, metric]
  }
  target_resource_id         = azurerm_synapse_workspace.synapse[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id

  log {
    category = "SynapseRbacOperations"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = true
    }
  }
  log {
    category = "GatewayApiRequests"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = true
    }
  }
  log {
    category = "BuiltinSqlReqsEnded"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = true
    }
  }
  log {
    category = "IntegrationPipelineRuns"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = true
    }
  }
  log {
    category = "IntegrationActivityRuns"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = true
    }
  }   
  log {
    category = "IntegrationTriggerRuns"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = true
    }
  }     

  metric {
    category = "AllMetrics"
    enabled  = false
    retention_policy {
      days    = 0
      enabled = true
    }
  }


}

