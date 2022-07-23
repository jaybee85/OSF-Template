output "tenant_id" {
  value = var.tenant_id
}

output "resource_group_name" {
  value = var.resource_group_name
}

output "aad_funcreg_id" {
  value = data.terraform_remote_state.layer1.outputs.aad_funcreg_id
}