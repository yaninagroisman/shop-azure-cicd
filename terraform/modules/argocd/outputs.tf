output "namespace" {
  description = "Namespace Argo CD runs in."
  value       = local.namespace
}

output "extension_version" {
  description = "Installed version of the Argo CD extension."
  value       = azurerm_kubernetes_cluster_extension.argocd.current_version
}
