output "cluster_id" {
  description = "ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "node_resource_group" {
  description = "Resource group AKS manages for nodes, disks and load balancers."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "oidc_issuer_url" {
  description = "OIDC issuer for workload identity federated credentials."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Principal ID of the kubelet identity (gets AcrPull on the registry)."
  value       = azurerm_user_assigned_identity.kubelet.principal_id
}

output "control_plane_identity_principal_id" {
  description = "Principal ID of the control plane identity (needs Network Contributor on a pre-created public IP)."
  value       = azurerm_user_assigned_identity.control_plane.principal_id
}
