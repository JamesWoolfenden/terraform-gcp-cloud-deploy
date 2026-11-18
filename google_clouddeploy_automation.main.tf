# Promotes a release to the next target ("@next") once its rollout on a
# selected target succeeds. Only a promote rule is configured: the pipeline
# uses the standard strategy, so there are no canary phases to advance.
resource "google_clouddeploy_automation" "main" {
  for_each = local.automation

  name              = "${var.name}-automation"
  location          = var.location
  delivery_pipeline = google_clouddeploy_delivery_pipeline.main.name
  service_account   = each.value.service_account
  description       = "Automatic promotion for ${var.name}"
  labels            = var.labels

  selector {
    dynamic "targets" {
      for_each = each.value.target_ids
      content {
        id = targets.value
      }
    }
  }

  rules {
    promote_release_rule {
      id                    = "promote-release"
      wait                  = each.value.promote_wait
      destination_target_id = "@next"
    }
  }

  depends_on = [
    google_clouddeploy_delivery_pipeline_iam_member.automation_operator,
    google_service_account_iam_member.automation_act_as,
  ]
}
