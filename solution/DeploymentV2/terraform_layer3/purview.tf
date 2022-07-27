resource "azuread_application_password" "purview_ir" {
  count                 = var.deploy_purview && var.is_vnet_isolated ? 1 : 0
  application_object_id = azuread_application.purview_ir[0].object_id
}
