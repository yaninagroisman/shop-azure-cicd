output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.name
}

output "monitor_workspace_id" {
  description = "ID of the Azure Monitor workspace (Managed Prometheus)."
  value       = azurerm_monitor_workspace.this.id
}

output "action_group_id" {
  description = "ID of the email action group, for further alert rules."
  value       = azurerm_monitor_action_group.email.id
}
