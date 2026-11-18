# Promotions created by the automation run their jobs as the execution SA, so
# the automation SA needs actAs on it (and only on it).
resource "google_service_account_iam_member" "automation_act_as" {
  for_each           = local.automation
  service_account_id = var.execution_service_account
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${each.value.service_account}"
}
