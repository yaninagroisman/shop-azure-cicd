variable "resource_group_name" {
  description = "Resource group for the network resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network."
  type        = string
}

variable "address_space" {
  description = "Address space of the VNet."
  type        = string

  validation {
    condition     = can(cidrhost(var.address_space, 0))
    error_message = "address_space must be a valid CIDR, e.g. 10.10.0.0/16."
  }
}

variable "aks_subnet_name" {
  description = "Name of the subnet for AKS nodes."
  type        = string
}

variable "aks_subnet_prefix" {
  description = "CIDR of the AKS node subnet. With CNI Overlay only nodes use it."
  type        = string

  validation {
    condition     = can(cidrhost(var.aks_subnet_prefix, 0))
    error_message = "aks_subnet_prefix must be a valid CIDR, e.g. 10.10.0.0/22."
  }
}

variable "nsg_name" {
  description = "Name of the subnet network security group."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
}
