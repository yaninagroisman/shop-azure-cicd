# Step 2 of the bootstrap (see README.md): after the first apply with local
# state, copy this file to backend.tf and migrate the state into the storage
# account the bootstrap just created:
#
#   terraform output -raw backend_config > backend.hcl
#   cp backend.tf.example backend.tf
#   terraform init -migrate-state -backend-config=backend.hcl
#
# The values come from backend.hcl (partial configuration), so nothing
# account-specific is committed.

terraform {
  backend "azurerm" {}
}
