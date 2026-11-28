# AKS identities, created before the cluster so their role assignments exist
# when AKS first needs them (no race on the first apply).
#
#   control plane identity ~ the EKS cluster IAM role: manages the load
#                            balancer and public IPs, joins nodes to the subnet
#   kubelet identity       ~ the EKS node IAM role: pulls images from ACR

resource "azurerm_user_assigned_identity" "control_plane" {
  name                = "id-${var.cluster_name}-control-plane"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "kubelet" {
  name                = "id-${var.cluster_name}-kubelet"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Bring-your-own subnet: the control plane must manage NICs and load balancer
# backends in it.
resource "azurerm_role_assignment" "control_plane_network" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.control_plane.principal_id
  principal_type       = "ServicePrincipal"
  description          = "AKS control plane: manage NICs and load balancer in the node subnet."
}

# Required when the kubelet identity is user-assigned: the control plane
# attaches it to the node VM scale set.
resource "azurerm_role_assignment" "control_plane_kubelet_operator" {
  scope                = azurerm_user_assigned_identity.kubelet.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.control_plane.principal_id
  principal_type       = "ServicePrincipal"
  description          = "AKS control plane: assign the kubelet identity to nodes."
}

# Kubernetes admin for the named people (Azure RBAC for Kubernetes, AD-09).
resource "azurerm_role_assignment" "cluster_admin" {
  for_each = toset(var.cluster_admin_object_ids)

  scope                = azurerm_kubernetes_cluster.this.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = each.value
  description          = "Cluster admin via Entra ID (local accounts are disabled)."
}
