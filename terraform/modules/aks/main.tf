resource "azurerm_kubernetes_cluster" "this" {
  # Accepted Checkov findings (owner decisions, see environments/dev/README.md):
  #checkov:skip=CKV_AZURE_115:Public API server with Entra ID, no local accounts and an IP allow-list (AD-09); a private cluster needs a jumpbox/VPN the Free Trial quota cannot hold.
  #checkov:skip=CKV_AZURE_170:Free tier without uptime SLA for the dev environment (AD-05).
  #checkov:skip=CKV_AZURE_171:Automatic upgrades are off on purpose: the environment is recreated by every apply (immutable infrastructure) and the 4 vCPU quota leaves no room for surge nodes.
  #checkov:skip=CKV_AZURE_116:Pod security is enforced by Pod Security Admission and Kyverno (AD-18), not the Azure Policy add-on.
  #checkov:skip=CKV_AZURE_117:OS disks are ephemeral (no managed disk to encrypt with a disk encryption set); persistent volumes use platform-managed encryption.
  #checkov:skip=CKV_AZURE_232:A single node pool runs system and application pods: a separate system pool needs nodes the 4 vCPU quota does not have (AD-05/06).
  #checkov:skip=CKV_AZURE_227:Host encryption needs the EncryptionAtHost feature registered on the subscription; not enabled for the dev environment.
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.cluster_name
  node_resource_group = var.node_resource_group_name

  kubernetes_version = var.kubernetes_version
  sku_tier           = "Free"
  support_plan       = "KubernetesOfficial"

  # No automatic upgrades (automatic_upgrade_channel omitted = none); node OS
  # images are fresh on every new cluster.
  node_os_upgrade_channel = "None"

  # Classic node pools managed by us, not Node Auto Provisioning (Karpenter):
  # one fixed pool is all the 4 vCPU quota allows.
  node_provisioning_profile {
    mode = "Manual"
  }

  default_node_pool {
    name                 = "system"
    vm_size              = var.node_vm_size
    node_count           = var.node_count
    auto_scaling_enabled = false # 2 nodes = the whole 4 vCPU quota
    vnet_subnet_id       = var.subnet_id
    os_sku               = "AzureLinux3"
    max_pods             = 110 # Kubernetes default, set explicitly (overlay allows up to 250)

    # The OS lives on the VM's local temporary disk: no managed OS disk to pay
    # for, faster node start, and nodes are rebuilt rather than repaired.
    os_disk_type    = "Ephemeral"
    os_disk_size_gb = var.os_disk_size_gb

    # Needed by azurerm to change pool properties by rotation. Rotation adds
    # nodes, which the 4 vCPU quota does not allow: prefer destroy + apply.
    temporary_name_for_rotation = "systemtmp"

    upgrade_settings {
      max_surge = "10%"
    }

    tags = var.tags
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.control_plane.id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
  }

  # Azure CNI Overlay with the Cilium dataplane, which also enforces
  # Kubernetes NetworkPolicies (AD-08). Egress through the load balancer (AD-10).
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    pod_cidr            = var.pod_cidr
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
    outbound_type       = "loadBalancer"
    load_balancer_sku   = "standard"
  }

  # Entra ID authentication + Azure RBAC for Kubernetes authorization; no
  # static kubeconfig credentials (AD-09).
  role_based_access_control_enabled = true
  local_account_disabled            = true

  azure_active_directory_role_based_access_control {
    tenant_id          = var.tenant_id
    azure_rbac_enabled = true
  }

  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  # Run Command (`az aks command invoke`) is on: Terraform applies the Argo CD
  # root Application through it (AD-39). It bypasses the IP allow-list, but
  # still requires Entra ID + Azure RBAC (runcommand/action plus Kubernetes
  # rights); accepted so the environment comes up with one apply.
  run_command_enabled = true

  # Workload Identity: pods exchange their service account token for an Entra
  # token (the IRSA / EKS Pod Identity equivalent).
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  workload_autoscaler_profile {
    keda_enabled = true # consumer scaling on Kafka lag, max 3 = partitions
  }

  storage_profile {
    disk_driver_enabled         = true # persistent volumes for Kafka and MongoDB
    snapshot_controller_enabled = true
    file_driver_enabled         = false
    blob_driver_enabled         = false
  }

  # Container Insights agent (AMA) with managed identity auth; what it
  # collects is defined by the data collection rule in modules/monitoring.
  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  # Managed Prometheus metrics add-on (default minimal ingestion profile).
  monitor_metrics {}

  # Removes unused (and possibly vulnerable) images from the nodes.
  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 48

  tags = var.tags

  depends_on = [
    # The control plane needs these permissions while the cluster is created;
    # Terraform cannot infer the dependency from references.
    azurerm_role_assignment.control_plane_network,
    azurerm_role_assignment.control_plane_kubelet_operator,
  ]
}

# Managed Gateway API CRDs + the App Routing Gateway API implementation
# (Istio-based, gateway class "approuting-istio") (AD-11). azurerm 5.15 has
# no argument for it; this follows Microsoft's documented azapi pattern.
resource "azapi_update_resource" "gateway_api" {
  type        = "Microsoft.ContainerService/managedClusters@2026-03-01"
  resource_id = azurerm_kubernetes_cluster.this.id

  body = {
    properties = {
      ingressProfile = {
        gatewayAPI = {
          installation = "Standard"
        }
        webAppRouting = {
          gatewayAPIImplementations = {
            appRoutingIstio = {
              mode = "Enabled"
            }
          }
        }
      }
    }
  }

  response_export_values = ["properties.ingressProfile"]
}
