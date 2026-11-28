# Remote state in the bootstrap storage account (Entra ID auth, blob lease
# locking). Values come from a git-ignored partial configuration:
#
#   cp backend.hcl.example backend.hcl    # fill in from the bootstrap outputs
#   terraform init -backend-config=backend.hcl
#
# In Azure Pipelines the same values are passed with -backend-config flags.

terraform {
  backend "azurerm" {}
}
