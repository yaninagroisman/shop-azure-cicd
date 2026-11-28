output "id" {
  description = "ID of the public IP."
  value       = azurerm_public_ip.this.id
}

output "ip_address" {
  description = "The public IP address."
  value       = azurerm_public_ip.this.ip_address
}

output "fqdn" {
  description = "FQDN of the IP (<label>.<region>.cloudapp.azure.com)."
  value       = azurerm_public_ip.this.fqdn
}

output "service_annotations" {
  description = "Annotations for the Gateway's LoadBalancer Service (Gateway spec.infrastructure.annotations) so it uses this IP."
  value = {
    "service.beta.kubernetes.io/azure-load-balancer-resource-group" = var.resource_group_name
    "service.beta.kubernetes.io/azure-pip-name"                     = azurerm_public_ip.this.name
  }
}
