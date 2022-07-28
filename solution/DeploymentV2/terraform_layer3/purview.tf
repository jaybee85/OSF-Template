resource "azuread_application_password" "purview_ir" {
  count                 = var.deploy_purview && var.is_vnet_isolated ? 1 : 0
  application_object_id = data.terraform_remote_state.layer2.outputs.purview_sp_object_id
}