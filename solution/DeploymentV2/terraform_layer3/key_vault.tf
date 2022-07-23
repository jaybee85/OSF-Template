resource "azurerm_key_vault_secret" "azure_function_secret" {
  count        = var.deploy_function_app ? 1 : 0
  name         = "AzureFunctionClientSecret"
  value        = azuread_application_password.function_app[0].value
  key_vault_id = data.terraform_remote_state.layer2.outputs.azurerm_key_vault_app_vault_id
}



