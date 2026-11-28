# Hybrid observability (AD-26):
#   metrics -> Managed Prometheus (Azure Monitor workspace) ~ Amazon Managed
#              Service for Prometheus
#   logs    -> Container Insights in Log Analytics, only our namespaces
#              ~ CloudWatch Container Insights / Logs
#   alerts  -> Prometheus alert rules -> email Action Group ~ CloudWatch
#              alarms -> SNS email topic
# Sized for a short-lived dev environment: minimal retention, a hard daily
# ingestion cap, every limit adjustable through variables.

# --- Logs ------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.log_analytics_workspace_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"

  # 30 days is the minimum and is included in the ingestion price.
  retention_in_days = var.log_retention_days

  # Ingestion stops for the rest of the day when the cap is reached: a
  # runaway log loop cannot burn the credit.
  daily_quota_gb = var.log_daily_quota_gb

  # Entra ID only: agents use the cluster's managed identity, no shared keys.
  local_authentication_enabled = false

  tags = var.tags
}

# Container Insights through a data collection rule (~ the CloudWatch agent
# configuration): logs and events only ("Logs and Events" cost preset), only
# the listed namespaces, every 5 minutes.
locals {
  container_insights_streams = [
    "Microsoft-ContainerLogV2",
    "Microsoft-KubeEvents",
    "Microsoft-KubePodInventory",
  ]
}

resource "azurerm_monitor_data_collection_rule" "container_insights" {
  name                = "MSCI-${var.location}-${var.cluster_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = "Container Insights: logs and events of the application namespaces."

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
      name                  = "ciworkspace"
    }
  }

  data_flow {
    streams      = local.container_insights_streams
    destinations = ["ciworkspace"]
  }

  data_sources {
    extension {
      name           = "ContainerInsightsExtension"
      extension_name = "ContainerInsights"
      streams        = local.container_insights_streams
      extension_json = jsonencode({
        dataCollectionSettings = {
          interval               = var.log_collection_interval
          namespaceFilteringMode = "Include"
          namespaces             = var.log_namespaces
          enableContainerLogV2   = true
        }
      })
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_data_collection_rule_association" "container_insights" {
  name                    = "ContainerInsightsExtension"
  target_resource_id      = var.cluster_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.container_insights.id
  description             = "Container Insights data collection for the cluster."
}

# --- Metrics -----------------------------------------------------------------

resource "azurerm_monitor_workspace" "this" {
  name                = var.monitor_workspace_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Wiring of the AKS metrics add-on to the workspace, as in Microsoft's
# Terraform example for managed Prometheus.
resource "azurerm_monitor_data_collection_endpoint" "prometheus" {
  name                = "MSProm-${var.location}-${var.cluster_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "Linux"
  tags                = var.tags
}

resource "azurerm_monitor_data_collection_rule" "prometheus" {
  name                        = "MSProm-${var.location}-${var.cluster_name}"
  resource_group_name         = var.resource_group_name
  location                    = var.location
  kind                        = "Linux"
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prometheus.id
  description                 = "Managed Prometheus: cluster metrics to the Azure Monitor workspace."

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.this.id
      name               = "MonitoringAccount1"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount1"]
  }

  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_data_collection_rule_association" "prometheus_rule" {
  name                    = "MSProm-${var.location}-${var.cluster_name}"
  target_resource_id      = var.cluster_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus.id
  description             = "Managed Prometheus data collection rule for the cluster."
}

resource "azurerm_monitor_data_collection_rule_association" "prometheus_endpoint" {
  # The name is fixed by Azure for endpoint associations.
  target_resource_id          = var.cluster_id
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prometheus.id
  description                 = "Managed Prometheus data collection endpoint for the cluster."
}

# Querying Prometheus data (portal Grafana dashboards, PromQL) is a data
# action: Owner/Contributor do not include it.
resource "azurerm_role_assignment" "metrics_reader" {
  for_each = var.metrics_reader_principal_ids

  scope                = azurerm_monitor_workspace.this.id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = each.value
  description          = "${each.key}: query Prometheus metrics and dashboards."
}

# --- Alerts --------------------------------------------------------------

resource "azurerm_monitor_action_group" "email" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  location            = "global"
  short_name          = substr(replace(var.action_group_name, "-", ""), 0, 12)

  dynamic "email_receiver" {
    for_each = toset(var.alert_emails)

    content {
      name                    = "email-${index(var.alert_emails, email_receiver.value)}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  tags = var.tags
}
