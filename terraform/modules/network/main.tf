# Virtual network for the AKS nodes (the Azure counterpart of a VPC with one
# private subnet). With Azure CNI Overlay only the nodes take VNet addresses;
# pods get addresses from a separate overlay range that never touches the VNet.

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "aks_nodes" {
  name                 = var.aks_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.aks_subnet_prefix]

  # Explicit outbound is provided by the AKS load balancer (AD-10); Azure no
  # longer gives new subnets implicit "default outbound access".
  default_outbound_access_enabled = false
}

# Subnet-level NSG (AD-N8): defense in depth on top of Cilium network
# policies. AKS also manages its own NSG on the node NICs.
#
# Only one explicit rule is needed. Azure's default rules already:
#   65000 AllowVnetInBound          - node-to-node and pod traffic inside the VNet
#   65001 AllowAzureLoadBalancerInBound - load balancer health probes
#   65500 DenyAllInBound            - everything else from the Internet
# Outbound stays open: nodes must reach ACR, Entra ID, Azure APIs and images.
resource "azurerm_network_security_group" "aks_nodes" {
  #checkov:skip=CKV_AZURE_160:Port 80 must be open for the Let's Encrypt HTTP-01 challenge and the HTTP to HTTPS redirect at the Gateway (AD-12).
  name                = var.nsg_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "AllowHttpHttpsFromInternet"
    description                = "Public traffic to the Gateway (TLS on 443; 80 for ACME HTTP-01 and redirect)."
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "*" # the load balancer frontend IP is not part of the VNet tag
    destination_port_ranges    = ["80", "443"]
  }
}

resource "azurerm_subnet_network_security_group_association" "aks_nodes" {
  subnet_id                 = azurerm_subnet.aks_nodes.id
  network_security_group_id = azurerm_network_security_group.aks_nodes.id
}
