# Runtime-specific roles the execution SA needs to deploy, e.g.
# roles/run.developer for Cloud Run or roles/container.developer for GKE.
resource "google_project_iam_member" "execution_extra" {
  for_each = toset(var.execution_service_account_roles)
  project  = data.google_project.current.project_id
  role     = each.value
  member   = "serviceAccount:${local.execution_service_account_email}"
}
