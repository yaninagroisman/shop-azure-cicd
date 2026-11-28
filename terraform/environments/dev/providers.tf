# Locally: `az login` (Azure CLI auth). In Azure Pipelines: workload identity
# federation through the sc-azure-tf-plan / sc-azure-tf-apply connections
# (ARM_USE_OIDC and friends are set by the pipeline task). No secrets here.

provider "azurerm" {
  subscription_id = var.subscription_id

  # Resource providers are registered once by the bootstrap (AD-34); the
  # pipeline identities do not have permission to register them.
  resource_provider_registrations = "none"

  storage_use_azuread = true

  features {
    # One apply / one destroy (AD-31): a destroyed environment must be
    # re-creatable right away with the same names.
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }

    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }

    resource_group {
      # Refuse to delete a resource group that still holds resources Terraform
      # does not know about, instead of silently deleting them.
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azapi" {
  subscription_id = var.subscription_id
}
