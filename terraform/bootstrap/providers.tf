# Authentication: the bootstrap is run once, locally, by the owner after
# `az login`. Both providers use the Azure CLI session; no keys or PATs.

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id

  # The state storage account has Shared Key access disabled, so the provider
  # must reach the blob data plane with Entra ID tokens.
  storage_use_azuread = true

  # azurerm 5.x registers nothing by default. We register exactly the
  # Resource Providers this project uses (AD-34), here and only here: the
  # pipeline identities do not need permission to register providers.
  resource_provider_registrations = "none"
  resource_providers_to_register  = local.resource_providers
}

provider "azuredevops" {
  org_service_url = var.azure_devops_org_url
  # use_cli defaults to true: the signed-in `az` account must be a member of
  # the Azure DevOps organization with rights to create projects.
}
