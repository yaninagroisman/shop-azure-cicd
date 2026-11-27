# Azure DevOps: the CI/CD side of the bootstrap (AD-31a). The code lives in
# GitHub (AD-28), so only Pipelines is enabled in the project.
#
# Not managed here (manual, one time): the organization itself, installing the
# "Azure Pipelines" GitHub App, and the free parallel job request.

resource "azuredevops_project" "this" {
  name               = var.azure_devops_project_name
  description        = "CI/CD for Marvellous Mischief Co. Source code is on GitHub."
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"

  features = {
    boards       = "disabled"
    repositories = "disabled"
    pipelines    = "enabled"
    testplans    = "disabled"
    artifacts    = "disabled"
  }
}

# Azure Resource Manager service connections with workload identity
# federation: the pipeline gets a short-lived OIDC token from Azure DevOps and
# exchanges it for an Entra token of the matching managed identity.
resource "azuredevops_serviceendpoint_azurerm" "pipeline" {
  for_each = local.pipeline_identities

  project_id                             = azuredevops_project.this.id
  service_endpoint_name                  = "sc-azure-${each.key}"
  description                            = "${each.value.description} Managed by Terraform."
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"

  credentials {
    serviceprincipalid = azurerm_user_assigned_identity.pipeline[each.key].client_id
  }

  azurerm_spn_tenantid      = data.azurerm_client_config.current.tenant_id
  azurerm_subscription_id   = data.azurerm_subscription.current.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.current.display_name
}

# The person who approves infrastructure changes and deployments.
data "azuredevops_users" "approver" {
  principal_name = var.approver_principal_name
}

locals {
  approver_id = one(data.azuredevops_users.approver.users).id
}

# Environment used by the infrastructure pipeline's apply stage.
resource "azuredevops_environment" "dev" {
  project_id  = azuredevops_project.this.id
  name        = "dev"
  description = "Azure dev environment (main stack). Deployments wait for manual approval."
}

resource "azuredevops_check_approval" "environment_dev" {
  project_id           = azuredevops_project.this.id
  target_resource_type = "environment"
  target_resource_id   = azuredevops_environment.dev.id

  approvers             = [local.approver_id]
  requester_can_approve = true # single-person project; with a team, set false
  instructions          = "Review the attached terraform plan before approving."
  timeout               = 1440 # minutes
}

# Defense in depth: the apply connection itself also requires approval, so a
# pipeline that skips the environment still cannot use it unattended.
resource "azuredevops_check_approval" "tf_apply_connection" {
  project_id           = azuredevops_project.this.id
  target_resource_type = "endpoint"
  target_resource_id   = azuredevops_serviceendpoint_azurerm.pipeline["tf-apply"].id

  approvers             = [local.approver_id]
  requester_can_approve = true
  instructions          = "This connection can change or destroy Azure resources."
  timeout               = 1440
}

# Apply and CI (image push) connections are usable from the main branch only:
# pull requests can build and plan, never deploy or publish.
resource "azuredevops_check_branch_control" "main_only" {
  for_each = local.main_branch_only

  project_id           = azuredevops_project.this.id
  target_resource_type = "endpoint"
  target_resource_id   = azuredevops_serviceendpoint_azurerm.pipeline[each.key].id
  display_name         = "Only ${var.main_branch}"
  allowed_branches     = var.main_branch

  verify_branch_protection         = false
  ignore_unknown_protection_status = false
  timeout                          = 1440
}
