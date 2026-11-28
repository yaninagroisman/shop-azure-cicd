variable "name" {
  description = "Name of the public IP."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the public IP (the main one, not the AKS node resource group)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "zones" {
  description = "Availability zones of the IP (all three = zone-redundant)."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "domain_name_label" {
  description = "DNS label: <label>.<region>.cloudapp.azure.com. Must be unique in the region."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,61}[a-z0-9]$", var.domain_name_label))
    error_message = "domain_name_label must be 3-63 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "control_plane_principal_id" {
  description = "Principal ID of the AKS control plane identity."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
}
