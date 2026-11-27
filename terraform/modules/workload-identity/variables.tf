variable "name" {
  description = "Name of the managed identity."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the identity."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace of the service account."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?$", var.namespace))
    error_message = "namespace must be a valid Kubernetes namespace name."
  }
}

variable "service_account" {
  description = "Kubernetes service account allowed to use the identity."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9.]{0,251}[a-z0-9])?$", var.service_account))
    error_message = "service_account must be a valid Kubernetes name."
  }
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
}
