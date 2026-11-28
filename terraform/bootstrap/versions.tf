terraform {
  # 1.11+ is needed for ephemeral resources and write-only arguments, which the
  # main stack uses to keep secrets out of state.
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.15"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.16"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }
}
