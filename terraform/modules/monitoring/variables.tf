variable "resource_group_name" {
  description = "Resource group for the monitoring resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "cluster_id" {
  description = "ID of the AKS cluster to monitor."
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster (used in rule names and alert rules)."
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace."
  type        = string
}

variable "monitor_workspace_name" {
  description = "Name of the Azure Monitor workspace (Managed Prometheus)."
  type        = string
}

variable "log_retention_days" {
  description = "Log retention in days. 30 is the minimum and costs nothing extra."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730."
  }
}

variable "log_daily_quota_gb" {
  description = "Daily log ingestion cap in GB; collection stops for the day when reached."
  type        = number
  default     = 0.25

  validation {
    condition     = var.log_daily_quota_gb >= 0.023
    error_message = "log_daily_quota_gb must be at least 0.023 (the Azure minimum)."
  }
}

variable "log_collection_interval" {
  description = "Container Insights collection interval (1m-30m). Longer = fewer records."
  type        = string
  default     = "5m"

  validation {
    condition     = can(regex("^([1-9]|[12][0-9]|30)m$", var.log_collection_interval))
    error_message = "log_collection_interval must be 1m to 30m."
  }
}

variable "log_namespaces" {
  description = "Kubernetes namespaces whose logs and events are collected."
  type        = list(string)

  validation {
    condition     = length(var.log_namespaces) > 0
    error_message = "List at least one namespace."
  }
}

variable "metrics_reader_principal_ids" {
  description = "Principals that may query Prometheus data (Monitoring Data Reader), keyed by a static label."
  type        = map(string)
  default     = {}
}

variable "action_group_name" {
  description = "Name of the email action group (first 12 letters/digits become its short name)."
  type        = string
}

variable "alert_emails" {
  description = "Email addresses that receive alerts."
  type        = list(string)

  validation {
    condition     = length(var.alert_emails) > 0 && alltrue([for e in var.alert_emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", e))])
    error_message = "Provide at least one valid email address."
  }
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
}
