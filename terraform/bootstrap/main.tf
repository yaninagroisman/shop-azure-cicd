data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

# Globally unique names (storage accounts) need a random part. It is created
# once with the bootstrap and never changes.
resource "random_string" "suffix" {
  length  = 4
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_resource_group" "bootstrap" {
  name     = "rg-${local.name_suffix}"
  location = var.location
  tags     = local.tags
}

# Remote state storage (AD-33). The main stack keeps its state here, so this
# account outlives every `terraform destroy` of the environment.
resource "azurerm_storage_account" "tfstate" {
  # Accepted Checkov findings (owner decision, see README "Accepted risks"):
  #checkov:skip=CKV_AZURE_59:Public endpoint required by Microsoft-hosted agents with dynamic IPs (AD-29). Access is Entra ID + RBAC only; shared keys are disabled.
  #checkov:skip=CKV2_AZURE_33:Private endpoints deferred (AD-14); they would also require a self-hosted agent inside the VNet.
  #checkov:skip=CKV_AZURE_33:Queue service is not used by this account.
  #checkov:skip=CKV2_AZURE_1:Microsoft-managed keys plus infrastructure (double) encryption; a CMK would need a separate Key Vault in the bootstrap.
  #checkov:skip=CKV_AZURE_206:ZRS (zone-redundant) chosen; the check only accepts geo-redundant SKUs, which a single-region learning project does not need.

  # st + project + tfstate + suffix, e.g. "stshoptfstate1a2b" (max 24 chars)
  name                     = "st${var.project}tfstate${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.bootstrap.name
  location                 = azurerm_resource_group.bootstrap.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS" # three copies across availability zones

  # Entra ID only: no account keys, no SAS tokens signed with them.
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  local_user_enabled              = false

  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  cross_tenant_replication_enabled  = false
  infrastructure_encryption_enabled = true # second layer of encryption at rest

  # Microsoft-hosted pipeline agents have changing IPs, so the endpoint stays
  # public; access is controlled by Entra ID + RBAC on the container.
  public_network_access = "Enabled"

  blob_properties {
    versioning_enabled = true # every state write keeps the previous version

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = local.tags

  lifecycle {
    # Terraform refuses to plan its deletion; the Azure lock below also
    # blocks deletion outside Terraform.
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "tfstate" {
  #checkov:skip=CKV2_AZURE_21:Blob read logging needs a Log Analytics workspace; the project's workspace lives in the main stack and is destroyed with it.
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

# Protects the state from accidental deletion, including by `terraform destroy`
# of this stack. Remove the lock deliberately before tearing the bootstrap down.
resource "azurerm_management_lock" "tfstate" {
  name       = "lock-tfstate-cannot-delete"
  scope      = azurerm_storage_account.tfstate.id
  lock_level = "CanNotDelete"
  notes      = "Terraform state for the ${var.project} project. Remove deliberately before deleting."
}
