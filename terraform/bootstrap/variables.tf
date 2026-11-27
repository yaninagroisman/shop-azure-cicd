variable "subscription_id" {
  description = "Azure subscription that hosts the project."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a GUID."
  }
}

variable "location" {
  description = "Azure region for the bootstrap resources (AD-01)."
  type        = string
  default     = "swedencentral"

  validation {
    condition     = contains(["swedencentral", "northeurope", "westeurope", "israelcentral"], var.location)
    error_message = "location must be one of the regions evaluated in the architecture plan: swedencentral, northeurope, westeurope, israelcentral."
  }
}

variable "project" {
  description = "Short project prefix used in resource names (AD-04)."
  type        = string
  default     = "shop"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,7}$", var.project))
    error_message = "project must be 2-8 lowercase letters or digits, starting with a letter (it ends up in storage account names)."
  }
}

variable "owner" {
  description = "Value of the 'owner' tag, e.g. a name or team. Not an email address."
  type        = string

  validation {
    condition     = length(trimspace(var.owner)) > 0 && !strcontains(var.owner, "@")
    error_message = "owner must be non-empty and must not be an email address."
  }
}

variable "repository_url" {
  description = "URL of the source repository, stored in the 'repo' tag."
  type        = string
  default     = "n/a"
}

variable "azure_devops_org_url" {
  description = "Azure DevOps organization URL, e.g. https://dev.azure.com/my-org."
  type        = string

  validation {
    condition     = can(regex("^https://dev\\.azure\\.com/[A-Za-z0-9][A-Za-z0-9-]*/?$", var.azure_devops_org_url))
    error_message = "azure_devops_org_url must look like https://dev.azure.com/<organization>."
  }
}

variable "azure_devops_project_name" {
  description = "Azure DevOps project that hosts the pipelines."
  type        = string
  default     = "shop"
}

variable "approver_principal_name" {
  description = "Azure DevOps principal name (usually the sign-in email) of the person who approves infrastructure changes."
  type        = string

  validation {
    condition     = strcontains(var.approver_principal_name, "@")
    error_message = "approver_principal_name must be a principal name such as user@example.com."
  }
}

variable "main_branch" {
  description = "The only branch allowed to use the apply and CI service connections."
  type        = string
  default     = "refs/heads/main"

  validation {
    condition     = startswith(var.main_branch, "refs/heads/")
    error_message = "main_branch must be a full ref such as refs/heads/main."
  }
}

variable "budget_amount" {
  description = "Monthly budget for the whole subscription, in the billing currency (AD-35)."
  type        = number
  default     = 100

  validation {
    condition     = var.budget_amount > 0
    error_message = "budget_amount must be positive."
  }
}

variable "budget_contact_emails" {
  description = "Who receives the budget alerts."
  type        = list(string)

  validation {
    condition     = length(var.budget_contact_emails) > 0 && alltrue([for e in var.budget_contact_emails : strcontains(e, "@")])
    error_message = "Provide at least one valid email address."
  }
}

variable "assignable_role_names" {
  description = <<-EOT
    The only built-in roles the tf-apply identity may assign or remove
    (ABAC condition on its RBAC Administrator role). These are the roles the
    main stack grants: kubelet AcrPull, CI AcrPush, AKS control plane network
    and identity roles, Key Vault data roles, and AKS admin for the owner.
  EOT
  type        = list(string)
  default = [
    "AcrPull",
    "AcrPush",
    "Network Contributor",
    "Managed Identity Operator",
    "Azure Kubernetes Service RBAC Cluster Admin",
    "Key Vault Secrets User",
    "Key Vault Secrets Officer",
    "Key Vault Crypto User",
    "Key Vault Crypto Officer",
    "Monitoring Metrics Publisher",
  ]

  validation {
    condition = length(setintersection(
      toset(var.assignable_role_names),
      toset(["Owner", "Contributor", "User Access Administrator", "Role Based Access Control Administrator"])
    )) == 0
    error_message = "Privileged roles must never be assignable by the pipeline: that would allow privilege escalation."
  }
}
