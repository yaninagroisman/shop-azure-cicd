# Pipeline identities: user-assigned managed identities (the Azure counterpart
# of IAM roles) that Azure Pipelines assumes through workload identity
# federation. No client secrets exist anywhere.

resource "azurerm_user_assigned_identity" "pipeline" {
  for_each = local.pipeline_identities

  name                = "id-${var.project}-${each.key}"
  resource_group_name = azurerm_resource_group.bootstrap.name
  location            = azurerm_resource_group.bootstrap.location
  tags                = local.tags
}

# Trust: "tokens issued by Azure DevOps for this exact service connection may
# act as this identity". Issuer and subject come from the service connection
# (see devops.tf), the same idea as an IAM OIDC trust policy.
resource "azurerm_federated_identity_credential" "pipeline" {
  for_each = local.pipeline_identities

  name                      = "ado-${var.azure_devops_project_name}-${each.key}"
  user_assigned_identity_id = azurerm_user_assigned_identity.pipeline[each.key].id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azuredevops_serviceendpoint_azurerm.pipeline[each.key].workload_identity_federation_issuer
  subject                   = azuredevops_serviceendpoint_azurerm.pipeline[each.key].workload_identity_federation_subject
}
