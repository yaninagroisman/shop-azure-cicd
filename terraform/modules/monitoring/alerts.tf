# Prometheus alert rules. Kept in their own file: Checkov's HCL parser cannot
# read the provider's required `for` argument and skips the whole file, so
# isolating it keeps the rest of the module scanned.

# A small set of symptom-based rules (from the Kubernetes community alerts
# Microsoft recommends). Application-level rules (Kafka consumer lag, DLQ
# growth) come with the Strimzi metrics in a later stage.
locals {
  alert_rules = {
    KubeNodeNotReady = {
      expression  = "kube_node_status_condition{job=\"kube-state-metrics\",condition=\"Ready\",status=\"true\"} == 0"
      for         = "PT15M"
      severity    = 1
      description = "Node {{ $labels.node }} has not been Ready for 15 minutes."
    }
    KubePodCrashLooping = {
      expression  = "max_over_time(kube_pod_container_status_waiting_reason{job=\"kube-state-metrics\",reason=\"CrashLoopBackOff\"}[5m]) >= 1"
      for         = "PT15M"
      severity    = 2
      description = "Pod {{ $labels.namespace }}/{{ $labels.pod }} ({{ $labels.container }}) is crash looping."
    }
    KubePodNotReady = {
      expression  = "sum by (namespace, pod) (kube_pod_status_phase{job=\"kube-state-metrics\",phase=~\"Pending|Unknown|Failed\"}) > 0"
      for         = "PT15M"
      severity    = 2
      description = "Pod {{ $labels.namespace }}/{{ $labels.pod }} has not been running for 15 minutes."
    }
    KubePersistentVolumeFillingUp = {
      expression  = "kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes > 0.8"
      for         = "PT10M"
      severity    = 2
      description = "Volume {{ $labels.persistentvolumeclaim }} in {{ $labels.namespace }} is more than 80% full (Kafka/MongoDB data)."
    }
    NodeCpuHigh = {
      expression  = "1 - avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) > 0.9"
      for         = "PT15M"
      severity    = 3
      description = "Node {{ $labels.instance }} CPU above 90% for 15 minutes: the 4 vCPU quota leaves no room to scale."
    }
    NodeMemoryHigh = {
      expression  = "1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes > 0.9"
      for         = "PT15M"
      severity    = 3
      description = "Node {{ $labels.instance }} memory above 90% for 15 minutes."
    }
  }
}

resource "azurerm_monitor_alert_prometheus_rule_group" "kubernetes" {
  name                = "kubernetes-${var.cluster_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  cluster_name        = var.cluster_name
  scopes              = [azurerm_monitor_workspace.this.id, var.cluster_id]
  rule_group_enabled  = true
  interval            = "PT1M"
  description         = "Kubernetes health alerts for ${var.cluster_name}."

  dynamic "rule" {
    for_each = local.alert_rules

    content {
      alert      = rule.key
      enabled    = true
      expression = rule.value.expression
      for        = rule.value.for
      severity   = rule.value.severity

      annotations = {
        description = rule.value.description
      }

      action {
        action_group_id = azurerm_monitor_action_group.email.id
      }

      alert_resolution {
        auto_resolved   = true
        time_to_resolve = "PT10M"
      }
    }
  }

  tags = var.tags
}
