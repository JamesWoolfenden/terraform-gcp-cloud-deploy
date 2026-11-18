resource "google_clouddeploy_delivery_pipeline_iam_member" "releasers" {
  for_each = toset(var.releasers)
  name     = google_clouddeploy_delivery_pipeline.main.name
  location = var.location
  role     = "roles/clouddeploy.releaser"
  member   = each.value
}
