resource "google_clouddeploy_delivery_pipeline" "main" {
  name        = var.name
  location    = var.location
  description = var.description
  labels      = var.labels

  serial_pipeline {
    dynamic "stages" {
      for_each = var.targets
      content {
        target_id = google_clouddeploy_target.main[stages.value.name].name
        profiles  = stages.value.profiles
      }
    }
  }
}
