# Workload identity for one Kubernetes service account ~ an IAM role for
# service accounts (IRSA): a managed identity plus a trust (federated
# credential) on the cluster's OIDC issuer. Pods using that service account
# get Entra ID tokens without any stored secret.

resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Trust only tokens for exactly this namespace/service account from this
# cluster (~ the sub condition of an IRSA trust policy).
resource "azurerm_federated_identity_credential" "this" {
  name                      = "aks-${var.namespace}-${var.service_account}"
  user_assigned_identity_id = azurerm_user_assigned_identity.this.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = var.oidc_issuer_url
  subject                   = "system:serviceaccount:${var.namespace}:${var.service_account}"
}
