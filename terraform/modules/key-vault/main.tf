# Key Vault ~ AWS Secrets Manager + KMS in one service. Authorization is Azure
# RBAC only (no access policies), on the vault and on individual secrets/keys.

# tflint-ignore: azurerm_resources_missing_prevent_destroy # one apply / one destroy (AD-31): the vault must be deletable
resource "azurerm_key_vault" "this" {
  # Accepted findings (owner decisions, see environments/dev/README.md):
  #checkov:skip=CKV_AZURE_109:Public endpoint without firewall on purpose: Terraform runs on Microsoft-hosted agents with unknown IPs; every request needs an Entra ID token with an RBAC role (owner decision, 2b).
  #checkov:skip=CKV_AZURE_189:Same as CKV_AZURE_109: public network access with RBAC-only authorization.
  #checkov:skip=CKV2_AZURE_32:A private endpoint is unreachable from Microsoft-hosted agents and the laptop (owner decision, 2b).
  #checkov:skip=CKV_AZURE_110:Purge protection would block deleting and re-creating the environment with the same names for up to 90 days (AD-31).
  #checkov:skip=CKV_AZURE_42:Soft delete is always on (7 days); purge protection is off for the same reason as CKV_AZURE_110.
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true

  # Soft delete cannot be disabled; the shortest retention, and no purge
  # protection, so `terraform destroy` can purge the vault (AD-31).
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  public_network_access_enabled = true

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = var.tags
}

# --- Data-plane administrators ---------------------------------------------
# Owner/Contributor manage the vault but cannot read or write its contents:
# whoever runs `terraform apply` needs these to create the secrets and the key.

locals {
  officer_roles = {
    secrets = "Key Vault Secrets Officer"
    crypto  = "Key Vault Crypto Officer"
  }

  officer_assignments = {
    for pair in setproduct(keys(var.officer_principal_ids), keys(local.officer_roles)) :
    "${pair[0]}-${pair[1]}" => {
      principal_id = var.officer_principal_ids[pair[0]]
      role         = local.officer_roles[pair[1]]
      label        = pair[0]
    }
  }
}

resource "azurerm_role_assignment" "officer" {
  for_each = local.officer_assignments

  scope                = azurerm_key_vault.this.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
  description          = "${each.value.label}: manage secrets and keys (Terraform)."
}

# New role assignments take a while to reach the Key Vault data plane; without
# the wait the first apply fails with 403 Forbidden. Only on create.
resource "time_sleep" "rbac_propagation" {
  create_duration = "90s"

  depends_on = [azurerm_role_assignment.officer]
}

# --- Generated secrets (AD-36) -----------------------------------------------
# The password is generated as an ephemeral value and written through a
# write-only argument: it exists only during the apply and in Key Vault, never
# in the plan or the state. Bump the version to rotate.

ephemeral "random_password" "this" {
  for_each = var.generated_secrets

  length           = 32
  special          = true
  override_special = "-_." # URL-safe: no escaping in connection strings
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
}

resource "azurerm_key_vault_secret" "generated" {
  #checkov:skip=CKV_AZURE_41:No expiry: the secret lives only as long as the environment (one apply / one destroy, AD-31); rotate by bumping the version.
  for_each = var.generated_secrets

  name             = each.key
  key_vault_id     = azurerm_key_vault.this.id
  value_wo         = ephemeral.random_password.this[each.key].result
  value_wo_version = var.secret_version
  content_type     = "password"
  tags             = var.tags

  depends_on = [time_sleep.rbac_propagation]
}

# --- Image signing key (AD-16) -----------------------------------------------
# Cosign signs through the Key Vault API (azurekms://...): the private key is
# generated inside Key Vault and never leaves it (~ an asymmetric KMS key).

# tflint-ignore: azurerm_resources_missing_prevent_destroy # deleted with the environment (AD-31); images are re-signed
resource "azurerm_key_vault_key" "signing" {
  #checkov:skip=CKV_AZURE_40:No expiry: the key lives only as long as the environment (AD-31); images are re-signed after re-creation.
  #checkov:skip=CKV_AZURE_112:HSM-backed keys need the Premium SKU; software-protected key for dev.
  name         = var.signing_key_name
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "EC"
  curve        = "P-256"
  key_opts     = ["sign", "verify"]
  tags         = var.tags

  depends_on = [time_sleep.rbac_propagation]
}

# --- Consumers ------------------------------------------------------------
# Read access per secret, not per vault: each workload sees only its own
# secrets.

locals {
  secret_reader_assignments = merge([
    for label, reader in var.secret_readers : {
      for secret in reader.secrets : "${label}-${secret}" => {
        principal_id = reader.principal_id
        secret       = secret
        label        = label
      }
    }
  ]...)
}

resource "azurerm_role_assignment" "secret_reader" {
  for_each = local.secret_reader_assignments

  scope                = "${azurerm_key_vault.this.id}/secrets/${azurerm_key_vault_secret.generated[each.value.secret].name}"
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.principal_id
  principal_type       = "ServicePrincipal"
  description          = "${each.value.label}: read ${each.value.secret}."
}

# Signing: Crypto User on the key only (sign + verify, no key management).
resource "azurerm_role_assignment" "signer" {
  for_each = var.signer_principal_ids

  scope                = "${azurerm_key_vault.this.id}/keys/${azurerm_key_vault_key.signing.name}"
  role_definition_name = "Key Vault Crypto User"
  principal_id         = each.value
  principal_type       = "ServicePrincipal"
  description          = "${each.key}: sign images with the Cosign key."
}
