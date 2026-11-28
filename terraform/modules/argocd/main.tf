# Argo CD as an AKS cluster extension (AD-32) ~ an EKS add-on: Azure installs
# and upgrades the upstream Helm chart; Terraform only declares it, so no
# helm/kubernetes provider has to reach the API server (the IP allow-list
# blocks Microsoft-hosted agents).

resource "azurerm_kubernetes_cluster_extension" "argocd" {
  name              = "argocd"
  cluster_id        = var.cluster_id
  extension_type    = "Microsoft.ArgoCD"
  release_namespace = local.namespace

  # Keys are upstream argo-cd chart values. The default is HA, which needs
  # four nodes; two nodes run the non-HA layout.
  configuration_settings = {
    "redis-ha.enabled" = "false"
  }
}

locals {
  namespace = "argocd"

  # App of apps: the root Application points at a folder of child
  # Applications in the separate GitOps repository (AD-40); Argo CD then
  # deploys everything else (Strimzi, Kafka, MongoDB, the application).
  root_application = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root"
      namespace = local.namespace
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_repo_revision
        path           = var.gitops_repo_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = local.namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
}

# The identity that applies the root Application needs Kubernetes rights in
# the argocd namespace (Azure RBAC for Kubernetes, scoped to the namespace).
# People applying from a laptop are cluster admins already.
resource "azurerm_role_assignment" "root_app_applier" {
  for_each = var.applier_principal_ids

  scope                = "${var.cluster_id}/namespaces/${local.namespace}"
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = each.value
  description          = "${each.key}: apply the Argo CD root Application (namespace ${local.namespace} only)."
}

# Applies the root Application through AKS Run Command (AD-39) ~ SSM Run
# Command: kubectl runs in a pod inside the cluster, called through ARM, so
# the API server IP allow-list does not get in the way. `az aks command
# invoke` handles the Entra token the cluster requires. Re-runs when the
# manifest or the cluster changes; retries while new role assignments
# propagate.
resource "terraform_data" "root_application" {
  triggers_replace = {
    cluster_id = var.cluster_id
    manifest   = sha256(yamlencode(local.root_application))
  }

  provisioner "local-exec" {
    interpreter = ["/usr/bin/env", "bash", "-c"]
    command     = file("${path.module}/apply-root-app.sh")

    environment = {
      SUBSCRIPTION_ID = var.subscription_id
      RESOURCE_GROUP  = var.resource_group_name
      CLUSTER_NAME    = var.cluster_name
      MANIFEST        = yamlencode(local.root_application)
    }
  }

  depends_on = [
    azurerm_kubernetes_cluster_extension.argocd, # the Application CRD
    azurerm_role_assignment.root_app_applier,
  ]
}
