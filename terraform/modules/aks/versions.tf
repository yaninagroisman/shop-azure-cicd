terraform {
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.15"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.14"
    }
  }
}
