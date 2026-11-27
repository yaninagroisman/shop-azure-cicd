variable "cluster_name" {
  description = "Name of the AKS cluster (also its DNS prefix)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the cluster and its identities."
  type        = string
}

variable "node_resource_group_name" {
  description = "Name of the resource group AKS creates for nodes, disks and load balancers."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "tenant_id" {
  description = "Entra ID tenant for Kubernetes authentication."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version; AKS picks its latest patch."
  type        = string

  validation {
    condition     = can(regex("^1\\.[0-9]{2}$", var.kubernetes_version))
    error_message = "kubernetes_version must be a minor version such as 1.36."
  }
}

variable "node_vm_size" {
  description = "VM size of the system node pool."
  type        = string
}

variable "node_count" {
  description = "Number of nodes. 2 x 2 vCPU is the whole Free Trial quota."
  type        = number

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 10
    error_message = "node_count must be between 1 and 10."
  }
}

variable "os_disk_size_gb" {
  description = "Ephemeral OS disk size; must fit the VM's temporary disk (75 GiB on D2ads_v5)."
  type        = number
}

variable "subnet_id" {
  description = "Subnet for the nodes."
  type        = string
}

variable "pod_cidr" {
  description = "Overlay CIDR for pods; must not overlap the VNet."
  type        = string
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services; must not overlap the VNet or pod CIDR."
  type        = string
}

variable "dns_service_ip" {
  description = "Cluster DNS service IP, inside service_cidr."
  type        = string
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDRs allowed to reach the Kubernetes API server."
  type        = list(string)

  validation {
    condition     = length(var.api_server_authorized_ip_ranges) > 0 && alltrue([for c in var.api_server_authorized_ip_ranges : can(cidrhost(c, 0))])
    error_message = "Provide at least one CIDR, e.g. 203.0.113.10/32. An empty list would open the API server to the Internet."
  }
}

variable "cluster_admin_object_ids" {
  description = "Entra object IDs that get Azure Kubernetes Service RBAC Cluster Admin."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
}
