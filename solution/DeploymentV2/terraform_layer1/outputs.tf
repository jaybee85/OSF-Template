output "tenant_id" {
  value = var.tenant_id
}

output "resource_group_name" {
  value = var.resource_group_name
}

output "function_app_reg" {
  value = azuread_application.function_app_reg[0]
}

output "aad_funcreg_id" {
  value = var.deploy_function_app ? azuread_application.function_app_reg[0].application_id : ""
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

output "rg_deployment_unique" {
  value = random_id.rg_deployment_unique
}