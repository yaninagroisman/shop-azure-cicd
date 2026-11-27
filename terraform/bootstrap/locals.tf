locals {
  # Region abbreviations for names (Cloud Adoption Framework style).
  location_short_names = {
    swedencentral = "swc"
    northeurope   = "neu"
    westeurope    = "weu"
    israelcentral = "ilc"
  }
  location_short = local.location_short_names[var.location]

  # <type>-<project>-<purpose>-<region>
  name_suffix = "${var.project}-bootstrap-${local.location_short}"

  tags = {
    project     = var.project
    environment = "bootstrap"
    owner       = var.owner
    managed-by  = "terraform"
    repo        = var.repository_url
    lifecycle   = "persistent"
  }

  # Every Resource Provider the bootstrap and the main stack use (AD-34).
  # Names must match the casing the Azure API returns: azurerm compares them
  # case-sensitively and silently skips a mismatch (it only logs a warning).
  # The API returns "microsoft.insights" in lower case.
  resource_providers = [
    "Microsoft.AlertsManagement",        # Prometheus alert rule groups
    "Microsoft.Compute",                 # AKS node pools are VM scale sets with managed disks
    "Microsoft.Consumption",             # budgets
    "Microsoft.ContainerRegistry",       # ACR
    "Microsoft.ContainerService",        # AKS
    "microsoft.insights",                # data collection rules, action groups, alerts
    "Microsoft.KeyVault",                # Key Vault
    "Microsoft.KubernetesConfiguration", # AKS cluster extensions (Argo CD, AD-32)
    "Microsoft.ManagedIdentity",         # user-assigned identities, federated credentials
    "Microsoft.Monitor",                 # Azure Monitor workspace (Managed Prometheus)
    "Microsoft.Network",                 # VNet, load balancer, public IP
    "Microsoft.OperationalInsights",     # Log Analytics
    "Microsoft.Storage",                 # Terraform state storage
  ]

  # Identities used by Azure Pipelines through workload identity federation.
  pipeline_identities = {
    tf-plan = {
      description = "Terraform plan in pull requests: read-only on Azure, writes only the state lock."
    }
    tf-apply = {
      description = "Terraform apply/destroy of the main stack. Main branch only, manual approval."
    }
    ci = {
      description = "Application CI: pushes and signs images. Main branch only."
    }
  }

  # Service connections that only the main branch may use.
  main_branch_only = toset(["tf-apply", "ci"])

  # Budget alerts (AD-35): actual spend at 25/50/80 %, forecast at 100 %.
  budget_notifications = [
    { threshold = 25, threshold_type = "Actual" },
    { threshold = 50, threshold_type = "Actual" },
    { threshold = 80, threshold_type = "Actual" },
    { threshold = 100, threshold_type = "Forecasted" },
  ]
}
