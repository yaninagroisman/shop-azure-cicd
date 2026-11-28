data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = local.names.resource_group
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "../../modules/network"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  vnet_name           = local.names.vnet
  address_space       = var.vnet_address_space
  aks_subnet_name     = local.names.aks_subnet
  aks_subnet_prefix   = var.aks_subnet_prefix
  nsg_name            = local.names.aks_subnet_nsg
  tags                = local.tags
}

module "aks" {
  source = "../../modules/aks"

  cluster_name             = local.names.aks
  resource_group_name      = azurerm_resource_group.this.name
  node_resource_group_name = local.names.aks_node_rg
  location                 = azurerm_resource_group.this.location
  tenant_id                = data.azurerm_client_config.current.tenant_id

  kubernetes_version = var.kubernetes_version
  node_vm_size       = var.node_vm_size
  node_count         = var.node_count
  os_disk_size_gb    = var.os_disk_size_gb

  subnet_id      = module.network.aks_subnet_id
  pod_cidr       = var.pod_cidr
  service_cidr   = var.service_cidr
  dns_service_ip = var.dns_service_ip

  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
  cluster_admin_object_ids        = var.cluster_admin_object_ids

  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  tags = local.tags
}

# --- Registry, secrets, pod identities (2b) --------------------------------

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

data "azurerm_user_assigned_identity" "pipeline" {
  for_each = local.pipeline_identities

  name                = "id-${var.project}-${each.key}"
  resource_group_name = local.bootstrap_resource_group
}

module "workload_identity" {
  source   = "../../modules/workload-identity"
  for_each = local.workload_identities

  name                = "${local.names.workload_identity_prefix}-${each.key}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  oidc_issuer_url     = module.aks.oidc_issuer_url
  namespace           = each.value.namespace
  service_account     = each.value.service_account
  tags                = local.tags
}

module "acr" {
  source = "../../modules/acr"

  name                = local.names.acr
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  pull_principal_ids = {
    aks-kubelet = module.aks.kubelet_identity_object_id
    # Kyverno reads Cosign signatures from the registry (AD-16).
    kyverno = module.workload_identity["kyverno"].principal_id
  }
  push_principal_ids = {
    ci = data.azurerm_user_assigned_identity.pipeline["ci"].principal_id
  }

  tags = local.tags
}

module "key_vault" {
  source = "../../modules/key-vault"

  name                = local.names.key_vault
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  # Whoever runs `terraform apply`: the pipeline identity and the people who
  # apply from a laptop.
  officer_principal_ids = merge(
    { tf-apply = data.azurerm_user_assigned_identity.pipeline["tf-apply"].principal_id },
    { for i, id in var.cluster_admin_object_ids : "admin-${i}" => id },
  )

  generated_secrets = [local.mongodb_root_secret, local.mongodb_app_secret]

  secret_readers = {
    # MongoDB creates the root user and the application user on first start.
    mongodb = {
      principal_id = module.workload_identity["mongodb"].principal_id
      secrets      = [local.mongodb_root_secret, local.mongodb_app_secret]
    }
    api = {
      principal_id = module.workload_identity["api"].principal_id
      secrets      = [local.mongodb_app_secret]
    }
    consumer = {
      principal_id = module.workload_identity["consumer"].principal_id
      secrets      = [local.mongodb_app_secret]
    }
    # Plan refreshes the secrets, which needs their values (accepted risk).
    tf-plan = {
      principal_id = data.azurerm_user_assigned_identity.pipeline["tf-plan"].principal_id
      secrets      = [local.mongodb_root_secret, local.mongodb_app_secret]
    }
  }

  signer_principal_ids = {
    ci = data.azurerm_user_assigned_identity.pipeline["ci"].principal_id
  }

  tags = local.tags
}

# --- Monitoring (2c, AD-26) -------------------------------------------------

module "monitoring" {
  source = "../../modules/monitoring"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  cluster_id          = module.aks.cluster_id
  cluster_name        = module.aks.cluster_name

  log_analytics_workspace_name = local.names.log_analytics
  monitor_workspace_name       = local.names.monitor_workspace
  action_group_name            = local.names.action_group

  log_retention_days      = var.log_retention_days
  log_daily_quota_gb      = var.log_daily_quota_gb
  log_collection_interval = var.log_collection_interval
  log_namespaces          = var.log_namespaces

  metrics_reader_principal_ids = { for i, id in var.cluster_admin_object_ids : "admin-${i}" => id }
  alert_emails                 = var.alert_emails

  tags = local.tags
}

# --- Entry point and GitOps (2d) --------------------------------------------

module "gateway_ip" {
  source = "../../modules/gateway-ip"

  name                       = local.names.gateway_ip
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  domain_name_label          = local.names.gateway_dns_label
  control_plane_principal_id = module.aks.control_plane_identity_principal_id
  tags                       = local.tags
}

module "argocd" {
  source = "../../modules/argocd"

  subscription_id     = var.subscription_id
  resource_group_name = azurerm_resource_group.this.name
  cluster_id          = module.aks.cluster_id
  cluster_name        = module.aks.cluster_name

  # The pipeline identity; people applying locally are cluster admins.
  applier_principal_ids = {
    tf-apply = data.azurerm_user_assigned_identity.pipeline["tf-apply"].principal_id
  }

  gitops_repo_url      = var.gitops_repo_url
  gitops_repo_revision = var.gitops_repo_revision
  gitops_repo_path     = var.gitops_repo_path

  # Contract with gitops-shop/apps/values.yaml (AD-45). Public values only.
  platform_values = {
    tenantId = data.azurerm_client_config.current.tenant_id
    registry = module.acr.login_server
    keyVault = {
      name    = module.key_vault.name
      secrets = { mongodbRoot = local.mongodb_root_secret, mongodbApp = local.mongodb_app_secret }
    }
    workloadIdentities = { for k, m in module.workload_identity : k => m.client_id }
    cosignPublicKey    = module.key_vault.signing_public_key_pem
    gateway = {
      fqdn        = module.gateway_ip.fqdn
      annotations = module.gateway_ip.service_annotations
    }
  }
}
