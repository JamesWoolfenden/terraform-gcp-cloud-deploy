resource "google_service_account" "deploy" {
  account_id   = "clouddeploy-execution"
  display_name = "Dedicated SA for Cloud Deploy render/deploy jobs"
}

resource "google_service_account" "automation" {
  account_id   = "clouddeploy-automation"
  display_name = "Dedicated SA for Cloud Deploy automatic promotion"
}
