# Container registry (AD-15) ~ a private ECR registry. Access only with Entra
# ID tokens through Azure RBAC: no admin user, no anonymous pull, no static
# registry credentials anywhere.
resource "azurerm_container_registry" "this" {
  # Basic SKU (AD-15): network rules, private endpoints, retention, quarantine,
  # trust policies, geo- and zone-redundancy are Premium-only features.
  #checkov:skip=CKV_AZURE_139:Basic SKU has no network rules or private endpoints; access needs an Entra ID token with AcrPull/AcrPush (AD-15).
  #checkov:skip=CKV_AZURE_163:Image scanning (Defender for Containers) is paid; images are scanned in the CI pipeline instead.
  #checkov:skip=CKV_AZURE_164:Content trust is Premium-only and deprecated; images are signed with Cosign and verified by Kyverno (AD-16).
  #checkov:skip=CKV_AZURE_165:Geo-replication is Premium-only; single-region dev environment.
  #checkov:skip=CKV_AZURE_166:Quarantine is Premium-only; Kyverno admits only signed images (AD-16).
  #checkov:skip=CKV_AZURE_167:Retention policy is Premium-only; the registry is deleted with the environment (AD-31).
  #checkov:skip=CKV_AZURE_233:Zone redundancy is Premium-only; dev environment.
  #checkov:skip=CKV_AZURE_237:Dedicated data endpoints are Premium-only.
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"

  admin_enabled          = false # no username/password credentials
  anonymous_pull_enabled = false

  # Classic AcrPull/AcrPush roles (not repository-scoped ABAC permissions).
  role_assignment_mode = "LegacyRegistryPermissions"

  tags = var.tags
}

# Nodes pull images with the kubelet identity (~ the EKS node role with
# ECR read access).
resource "azurerm_role_assignment" "pull" {
  for_each = var.pull_principal_ids

  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = each.value
  principal_type       = "ServicePrincipal"
  description          = "${each.key}: pull images."
}

# CI pushes images and Cosign signatures (signatures are OCI artifacts).
resource "azurerm_role_assignment" "push" {
  for_each = var.push_principal_ids

  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPush"
  principal_id         = each.value
  principal_type       = "ServicePrincipal"
  description          = "${each.key}: push images and signatures."
}
