output "tenant_id" {
  value = var.tenant_id
}

output "resource_group_name" {
  value = var.resource_group_name
}

/*Variables for Naming Module*/
output "naming_unique_seed" {
  value = data.terraform_remote_state.layer2.outputs.naming_unique_seed
}

output "naming_unique_suffix" {
  value = data.terraform_remote_state.layer2.outputs.naming_unique_suffix
}

output "aad_funcreg_id" {
  value = data.terraform_remote_state.layer2.outputs.aad_funcreg_id
}

output "aad_webreg_id" {
  value = data.terraform_remote_state.layer2.outputs.aad_webreg_id
}

output "webapp_name" {
  value = data.terraform_remote_state.layer2.outputs.webapp_name
}

output "functionapp_name" {
  value = data.terraform_remote_state.layer2.outputs.functionapp_name
}