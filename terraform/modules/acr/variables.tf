variable "name" {
  description = "Registry name: 5-50 letters and digits, globally unique."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.name))
    error_message = "name must be 5-50 letters or digits."
  }
}

variable "resource_group_name" {
  description = "Resource group for the registry."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "pull_principal_ids" {
  description = "Service principals (managed identities) that get AcrPull, keyed by a static label."
  type        = map(string)
  default     = {}
}

variable "push_principal_ids" {
  description = "Service principals (managed identities) that get AcrPush, keyed by a static label."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
}
