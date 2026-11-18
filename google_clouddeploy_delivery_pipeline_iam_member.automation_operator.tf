# The automation SA promotes releases on this pipeline only, rather than
# holding clouddeploy.operator project-wide.
resource "google_clouddeploy_delivery_pipeline_iam_member" "automation_operator" {
  for_each = local.automation
  name     = google_clouddeploy_delivery_pipeline.main.name
  location = var.location
  role     = "roles/clouddeploy.operator"
  member   = "serviceAccount:${each.value.service_account}"
}
