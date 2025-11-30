// outputs.tf
// Outputs for Azure dev environment

output "container_registry_login_server" {
  description = "ACR login server URL"
  value       = azurerm_container_registry.this.login_server
}

output "container_app_fqdn" {
  description = "Container App fully qualified domain name (URL to access the app)"
  value       = module.app.container_app_fqdn
}

output "container_app_name" {
  description = "Name of the Container App"
  value       = module.app.container_app_name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.app.resource_group_name
}
