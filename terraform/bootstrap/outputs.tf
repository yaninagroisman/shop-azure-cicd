output "state_resource_group_name" {
  description = "Resource group of the Terraform state storage."
  value       = azurerm_resource_group.bootstrap.name
}

output "state_storage_account_name" {
  description = "Storage account holding all Terraform state files."
  value       = azurerm_storage_account.tfstate.name
}

output "state_container_name" {
  description = "Blob container for Terraform state."
  value       = azurerm_storage_container.tfstate.name
}

output "backend_config" {
  description = "Partial backend configuration for this stack: terraform output -raw backend_config > backend.hcl"
  value       = <<-EOT
    resource_group_name  = "${azurerm_resource_group.bootstrap.name}"
    storage_account_name = "${azurerm_storage_account.tfstate.name}"
    container_name       = "${azurerm_storage_container.tfstate.name}"
    key                  = "bootstrap.tfstate"
    use_azuread_auth     = true
  EOT
}

output "pipeline_identity_client_ids" {
  description = "Client IDs of the pipeline managed identities (not secrets)."
  value       = { for k, v in azurerm_user_assigned_identity.pipeline : k => v.client_id }
}

output "pipeline_identity_principal_ids" {
  description = "Object IDs of the pipeline identities; the main stack grants them roles on its resources."
  value       = { for k, v in azurerm_user_assigned_identity.pipeline : k => v.principal_id }
}

output "service_connection_names" {
  description = "Names to reference from pipeline YAML (azureSubscription: ...)."
  value       = { for k, v in azuredevops_serviceendpoint_azurerm.pipeline : k => v.service_endpoint_name }
}

output "azure_devops_project_url" {
  description = "Azure DevOps project."
  value       = "${trimsuffix(var.azure_devops_org_url, "/")}/${azuredevops_project.this.name}"
}
