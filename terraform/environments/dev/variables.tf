variable "subscription_id" {
  description = "Azure subscription that hosts the project."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a GUID."
  }
}

variable "location" {
  description = "Azure region (AD-01)."
  type        = string
  default     = "swedencentral"

  validation {
    condition     = contains(["swedencentral", "northeurope", "westeurope", "israelcentral"], var.location)
    error_message = "location must be one of: swedencentral, northeurope, westeurope, israelcentral."
  }
}

variable "project" {
  description = "Short project prefix used in resource names (AD-04)."
  type        = string
  default     = "shop"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,7}$", var.project))
    error_message = "project must be 2-8 lowercase letters or digits, starting with a letter."
  }
}

variable "environment" {
  description = "Environment name used in resource names and tags."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z]{2,8}$", var.environment))
    error_message = "environment must be 2-8 lowercase letters."
  }
}

variable "owner" {
  description = "Value of the 'owner' tag, e.g. a first name. Not an email address."
  type        = string

  validation {
    condition     = length(trimspace(var.owner)) > 0 && !strcontains(var.owner, "@")
    error_message = "owner must be non-empty and must not be an email address."
  }
}

variable "repository_url" {
  description = "Source repository, stored in the 'repo' tag."
  type        = string
  default     = "n/a"
}

# --- Network (CIDR plan from the architecture: VNet and overlay ranges must not overlap)

variable "vnet_address_space" {
  description = "VNet address space."
  type        = string
  default     = "10.10.0.0/16"
}

variable "aks_subnet_prefix" {
  description = "AKS node subnet. With CNI Overlay only nodes take addresses from it."
  type        = string
  default     = "10.10.0.0/22"
}

variable "pod_cidr" {
  description = "Overlay range for pods (not routed in the VNet)."
  type        = string
  default     = "192.168.0.0/16"
}

variable "service_cidr" {
  description = "Range for Kubernetes services."
  type        = string
  default     = "172.16.0.0/16"
}

variable "dns_service_ip" {
  description = "Cluster DNS IP inside service_cidr."
  type        = string
  default     = "172.16.0.10"
}

# --- AKS (AD-05/06, approved upgrade policy)

variable "kubernetes_version" {
  description = "Kubernetes minor version; AKS uses its latest patch."
  type        = string
  default     = "1.36"
}

variable "node_vm_size" {
  description = "VM size of the node pool."
  type        = string
  default     = "Standard_D2ads_v5"
}

variable "node_count" {
  description = "Number of nodes. 2 x D2ads_v5 = 4 vCPU = the whole Free Trial regional quota."
  type        = number
  default     = 2
}

variable "os_disk_size_gb" {
  description = "Ephemeral OS disk size; must fit the 75 GiB temporary disk of D2ads_v5."
  type        = number
  default     = 64
}

variable "api_server_authorized_ip_ranges" {
  description = "Your public IP(s) as CIDR, e.g. [\"203.0.113.10/32\"]. Only these can reach the Kubernetes API (AD-09)."
  type        = list(string)
}

variable "cluster_admin_object_ids" {
  description = "Entra object IDs of the people who operate the environment: Kubernetes cluster admin and Key Vault Secrets/Crypto Officer (az ad signed-in-user show --query id -o tsv)."
  type        = list(string)

  validation {
    condition     = length(var.cluster_admin_object_ids) > 0
    error_message = "At least one cluster admin is required: local accounts are disabled, so nobody else could log in."
  }
}
