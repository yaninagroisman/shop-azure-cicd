output "resource_group_name" {
  description = "Resource group of the dev environment."
  value       = azurerm_resource_group.this.name
}

output "aks_cluster_name" {
  description = "AKS cluster name."
  value       = module.aks.cluster_name
}

output "aks_node_resource_group" {
  description = "Resource group AKS manages (nodes, disks, load balancer)."
  value       = module.aks.node_resource_group
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer for workload identity."
  value       = module.aks.oidc_issuer_url
}

output "kubeconfig_command" {
  description = "Get Entra ID based credentials (no static secrets), then convert for kubectl."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${module.aks.cluster_name} && kubelogin convert-kubeconfig -l azurecli"
}

output "acr_login_server" {
  description = "Registry host for image references."
  value       = module.acr.login_server
}

output "acr_name" {
  description = "Registry name (az acr login --name ...)."
  value       = module.acr.name
}

output "key_vault_name" {
  description = "Key Vault name (SecretProviderClass keyvaultName)."
  value       = module.key_vault.name
}

output "tenant_id" {
  description = "Entra ID tenant (SecretProviderClass tenantId)."
  value       = data.azurerm_client_config.current.tenant_id
}

output "mongodb_secret_names" {
  description = "Key Vault secret names for MongoDB (names only, values never leave Key Vault)."
  value       = module.key_vault.secret_names
}

output "workload_identity_client_ids" {
  description = "Client IDs for the azure.workload.identity/client-id service account annotations (not secrets)."
  value       = { for k, m in module.workload_identity : k => m.client_id }
}

output "cosign_key_uri" {
  description = "cosign sign --key <this> <image>"
  value       = module.key_vault.signing_key_uri
}

output "cosign_public_key_pem" {
  description = "Public Cosign key for Kyverno verifyImages."
  value       = module.key_vault.signing_public_key_pem
}
