resource "google_project_iam_member" "execution_job_runner" {
  project = data.google_project.current.project_id
  role    = "roles/clouddeploy.jobRunner"
  member  = "serviceAccount:${local.execution_service_account_email}"
}
