# holden:ignore:HLD_TF_026 — examples intentionally use ../../ to reference the local module root
module "cloud_deploy" {
  source                          = "../../"
  name                            = "example-app"
  location                        = "europe-west2"
  description                     = "Cloud Run delivery pipeline: dev -> staging -> prod"
  execution_service_account       = google_service_account.deploy.id
  execution_service_account_roles = ["roles/run.developer"]

  targets = [
    { name = "dev", run_location = "europe-west2", profiles = ["dev"] },
    { name = "staging", run_location = "europe-west2", profiles = ["staging"] },
    { name = "prod", run_location = "europe-west2", profiles = ["prod"], require_approval = true },
  ]

  automation = {
    service_account = google_service_account.automation.email
    target_ids      = ["dev"]
  }

  labels = {
    app = "example"
  }
}
