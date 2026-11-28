output "id" {
  description = "ID of the registry."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "Name of the registry (az acr login --name ...)."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Registry host for image references, e.g. <login_server>/shop-api:<tag>."
  value       = azurerm_container_registry.this.login_server
}
