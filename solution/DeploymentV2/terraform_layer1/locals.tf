locals {
  webapp_name                  = (var.webapp_name != "" ? var.webapp_name : module.naming.app_service.name_unique)
  webapp_url                   = "https://${local.webapp_name}.azurewebsites.net"
  functionapp_name             = (var.functionapp_name != "" ? var.functionapp_name : module.naming.function_app.name_unique)
  functionapp_url              = "https://${local.functionapp_name}.azurewebsites.net"
  aad_webapp_name              = (var.aad_webapp_name != "" ? var.aad_webapp_name : "ADS GoFast Web Portal (${var.environment_tag})")
  aad_functionapp_name         = (var.aad_functionapp_name != "" ? var.aad_functionapp_name : "ADS GoFast Orchestration App (${var.environment_tag})")
 

  tags = {
    Environment = var.environment_tag
    Owner       = var.owner_tag
    Author      = var.author_tag
    Application = var.app_name
    CreatedDate = timestamp()
  }

}


