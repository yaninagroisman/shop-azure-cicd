variable "name" {
  description = "Vault name: 3-24 letters, digits and hyphens, globally unique."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.name)) && !strcontains(var.name, "--")
    error_message = "name must be 3-24 characters: letters, digits and single hyphens, starting with a letter."
  }
}

variable "resource_group_name" {
  description = "Resource group for the vault."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "tenant_id" {
  description = "Entra ID tenant of the vault."
  type        = string
}

variable "officer_principal_ids" {
  description = "Principals that run Terraform and manage vault contents (Secrets Officer + Crypto Officer), keyed by a static label."
  type        = map(string)

  validation {
    condition     = length(var.officer_principal_ids) > 0
    error_message = "At least one officer is needed, otherwise Terraform cannot write the secrets."
  }
}

variable "generated_secrets" {
  description = "Names of secrets whose values Terraform generates (ephemeral, never in state)."
  type        = set(string)
  default     = []
}

variable "secret_version" {
  description = "Write-only version of the generated secrets; increase it to generate and store new values."
  type        = number
  default     = 1
}

variable "secret_readers" {
  description = "Who may read which generated secret (Key Vault Secrets User on the secret), keyed by a static label."
  type = map(object({
    principal_id = string
    secrets      = set(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for r in values(var.secret_readers) : length(setsubtract(r.secrets, var.generated_secrets)) == 0])
    error_message = "secret_readers may only reference names listed in generated_secrets."
  }
}

variable "signing_key_name" {
  description = "Name of the Cosign signing key."
  type        = string
  default     = "cosign"
}

variable "signer_principal_ids" {
  description = "Principals allowed to sign with the key (Key Vault Crypto User on the key), keyed by a static label."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
}
