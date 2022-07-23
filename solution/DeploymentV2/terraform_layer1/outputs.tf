output "tenant_id" {
  value = var.tenant_id
}

output "resource_group_name" {
  value = var.resource_group_name
}

output "random_uuid_function_app_reg_role_id" {
  value = random_uuid.function_app_reg_role_id.result
}


/*Variables for Naming Module*/
output "naming_unique_seed" {
  value = module.naming.unique-seed
}

output "naming_unique_suffix" {
  value = substr(module.naming.unique-seed, 0, 4)
}

/*Service Names*/
output "aad_funcreg_id" {
  value = var.deploy_function_app ? azuread_application.function_app_reg[0].application_id : ""
}

output "azuread_service_principal_function_app_object_id" {
  value = var.deploy_function_app ? azuread_service_principal.function_app[0].object_id : ""
}

output "azuread_application_function_app_reg_object_id" {
  value = var.deploy_function_app ? azuread_application.function_app_reg[0].object_id : ""
}

output "aad_webreg_id" {
  value = var.deploy_web_app ? azuread_application.web_reg[0].application_id : ""
}




output "webapp_name" {
  value = local.webapp_name
}

output "functionapp_name" {
  value = local.functionapp_name
}

