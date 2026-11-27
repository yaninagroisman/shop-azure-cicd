# Azure RBAC for the bootstrap: who may do what with the state and the
# subscription. Roles on resources created later (ACR, Key Vault, AKS) are
# granted by the main stack, scoped to those resources.

# --- Terraform state access (blob data plane, Entra ID only) ---------------
# Owner/Contributor do not include data actions, so even the subscription
# owner needs an explicit data role to read and write state blobs.

resource "azurerm_role_assignment" "state_owner" {
  scope                = azurerm_storage_container.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  description          = "Owner running Terraform locally: read/write state."
}

# Plan also writes: acquiring the state lock is a blob lease.
resource "azurerm_role_assignment" "state_pipeline" {
  for_each = toset(["tf-plan", "tf-apply"])

  scope                = azurerm_storage_container.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.pipeline[each.key].principal_id
  principal_type       = "ServicePrincipal"
  description          = "${each.key}: read/write Terraform state and its lock."
}

# --- tf-plan: read-only on the subscription --------------------------------

resource "azurerm_role_assignment" "plan_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.pipeline["tf-plan"].principal_id
  principal_type       = "ServicePrincipal"
  description          = "tf-plan: refresh state and compute plans."
}

# --- tf-apply: manage resources, assign only an allow-list of roles --------
# Subscription scope so the main stack can create and delete its own
# resource groups (one apply / one destroy, AD-31).

resource "azurerm_role_assignment" "apply_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.pipeline["tf-apply"].principal_id
  principal_type       = "ServicePrincipal"
  description          = "tf-apply: create, change and destroy the main stack."
}

data "azurerm_role_definition" "assignable" {
  for_each = toset(var.assignable_role_names)

  name  = each.value
  scope = data.azurerm_subscription.current.id
}

locals {
  # GUIDs of the roles tf-apply may hand out.
  assignable_role_guids = join(", ", sort([for r in data.azurerm_role_definition.assignable : basename(r.id)]))

  # ABAC condition (version 2.0): role assignments may be written or deleted
  # only for the allow-listed roles. Everything else, e.g. granting Owner or
  # Contributor to itself, is denied: no privilege escalation path.
  rbac_admin_condition = <<-EOT
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
     )
     OR
     (
      @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.assignable_role_guids}}
     )
    )
    AND
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
     )
     OR
     (
      @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.assignable_role_guids}}
     )
    )
  EOT
}

resource "azurerm_role_assignment" "apply_rbac_admin" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azurerm_user_assigned_identity.pipeline["tf-apply"].principal_id
  principal_type       = "ServicePrincipal"
  condition            = local.rbac_admin_condition
  condition_version    = "2.0"
  description          = "tf-apply: create role assignments for the allow-listed roles only."
}

# --- ci: nothing at subscription scope --------------------------------------
# AcrPush on the registry and Crypto User on the signing key are granted by the
# main stack, which creates those resources.
