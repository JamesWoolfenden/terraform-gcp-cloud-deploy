resource "google_clouddeploy_target" "main" {
  for_each = local.targets

  name              = each.key
  location          = var.location
  description       = each.value.description
  require_approval  = each.value.require_approval
  deploy_parameters = each.value.deploy_parameters
  labels            = var.labels

  dynamic "run" {
    for_each = each.value.run
    content {
      location = run.value
    }
  }

  dynamic "gke" {
    for_each = each.value.gke
    content {
      cluster     = gke.value
      internal_ip = true
    }
  }

  # Render/deploy/verify jobs run as the dedicated execution SA, optionally on
  # a private Cloud Build worker pool, never as the Compute Engine default SA.
  execution_configs {
    usages            = ["RENDER", "DEPLOY", "VERIFY", "PREDEPLOY", "POSTDEPLOY"]
    service_account   = local.execution_service_account_email
    worker_pool       = var.worker_pool
    artifact_storage  = var.artifact_storage
    execution_timeout = var.execution_timeout
  }

  depends_on = [google_project_iam_member.execution_job_runner]

  lifecycle {
    # GKE targets reach the control plane on its private IP (internal_ip =
    # true); the default Cloud Build pool cannot route there.
    precondition {
      condition     = length(each.value.gke) == 0 || var.worker_pool != null
      error_message = "var.worker_pool must be set when any target uses gke_cluster: GKE targets are reached on the control plane's internal IP, which the default Cloud Build pool cannot route to"
    }
  }
}
