# Static public IP for the application Gateway (AD-37) ~ an Elastic IP that
# the AWS Load Balancer Controller attaches to an NLB.
#
# Terraform owns the IP in the main resource group, so the FQDN is known
# before anything is deployed and `terraform destroy` removes it. The Gateway
# (a LoadBalancer Service created by App Routing) picks it up through the
# annotations in the `service_annotations` output.

resource "azurerm_public_ip" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = var.zones

  # <label>.<region>.cloudapp.azure.com: the free DNS name used instead of a
  # domain (AD-12); cert-manager requests the Let's Encrypt certificate for it.
  domain_name_label = var.domain_name_label

  tags = var.tags
}

# The AKS control plane (cloud controller) attaches the IP to its load
# balancer. Scoped to this one IP, not the resource group.
resource "azurerm_role_assignment" "control_plane" {
  scope                = azurerm_public_ip.this.id
  role_definition_name = "Network Contributor"
  principal_id         = var.control_plane_principal_id
  principal_type       = "ServicePrincipal"
  description          = "AKS control plane: attach the Gateway public IP to the load balancer."
}
