# TFLint configuration shared by all stacks (run from a stack directory with
# `tflint --config=../.tflint.hcl`, or `--chdir`). Used locally and in CI.

config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "azurerm" {
  enabled = true
  version = "0.33.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}
