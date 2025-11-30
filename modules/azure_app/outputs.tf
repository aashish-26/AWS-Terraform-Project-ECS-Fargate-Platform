output "resource_group_name" {
  description = "Name of the resource group containing the app."
  value       = azurerm_resource_group.this.name
}

output "container_app_name" {
  description = "Name of the Azure Container App."
  value       = azurerm_container_app.this.name
}

output "container_app_fqdn" {
  description = "Fully qualified domain name (URL) of the Container App."
  value       = azurerm_container_app.this.latest_revision_fqdn
}

output "container_app_environment_id" {
  description = "ID of the Container App Environment."
  value       = azurerm_container_app_environment.this.id
}

output "managed_identity_id" {
  description = "ID of the user-assigned managed identity used by the Container App."
  value       = azurerm_user_assigned_identity.container_app.id
}


