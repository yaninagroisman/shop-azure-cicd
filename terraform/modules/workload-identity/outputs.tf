output "id" {
  description = "ID of the managed identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "client_id" {
  description = "Client ID for the azure.workload.identity/client-id service account annotation (not a secret)."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "principal_id" {
  description = "Object ID used in role assignments."
  value       = azurerm_user_assigned_identity.this.principal_id
}
