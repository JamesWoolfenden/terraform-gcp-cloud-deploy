# Creating a release or rollout requires actAs on the execution SA, so each
# releaser gets serviceAccountUser on that SA only (not project-wide).
resource "google_service_account_iam_member" "releasers_act_as" {
  for_each           = toset(var.releasers)
  service_account_id = var.execution_service_account
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}
