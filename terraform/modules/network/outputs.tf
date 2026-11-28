output "vnet_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "aks_subnet_id" {
  description = "ID of the AKS node subnet. The NSG association is part of this module, so consumers depend on the subnet only after it is protected."
  value       = azurerm_subnet_network_security_group_association.aks_nodes.subnet_id
}

output "nsg_id" {
  description = "ID of the subnet network security group."
  value       = azurerm_network_security_group.aks_nodes.id
}
