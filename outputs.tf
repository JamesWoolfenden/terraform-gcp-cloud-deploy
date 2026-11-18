output "pipeline_id" {
  value       = google_clouddeploy_delivery_pipeline.main.id
  description = "ID of the delivery pipeline"
}

output "pipeline_name" {
  value       = google_clouddeploy_delivery_pipeline.main.name
  description = "Name of the delivery pipeline"
}

output "target_ids" {
  value       = { for k, t in google_clouddeploy_target.main : k => t.id }
  description = "Map of target name to target ID"
}

output "automation_id" {
  value       = try(google_clouddeploy_automation.main["main"].id, null)
  description = "ID of the automation, null when var.automation is null"
}
