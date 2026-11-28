variable "subscription_id" {
  description = "Subscription of the cluster (passed to az aks command invoke)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group of the cluster."
  type        = string
}

variable "cluster_id" {
  description = "ID of the AKS cluster."
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "applier_principal_ids" {
  description = "Principals that apply the root Application (e.g. the tf-apply pipeline identity), keyed by a static label."
  type        = map(string)
  default     = {}
}

variable "gitops_repo_url" {
  description = "HTTPS URL of the GitOps repository (public: no credentials configured)."
  type        = string

  validation {
    condition     = can(regex("^https://", var.gitops_repo_url))
    error_message = "gitops_repo_url must be an https:// URL."
  }
}

variable "gitops_repo_revision" {
  description = "Branch, tag or commit Argo CD follows."
  type        = string
  default     = "main"
}

variable "gitops_repo_path" {
  description = "Folder with the child Application manifests."
  type        = string
  default     = "apps"
}

variable "platform_values" {
  description = "Non-secret per-environment values passed to the GitOps app-of-apps chart (Helm valuesObject)."
  type        = any
  default     = {}
}
