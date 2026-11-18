locals {
  # var.execution_service_account is a google_service_account id
  # ("projects/P/serviceAccounts/EMAIL"); execution_configs and IAM need the email.
  execution_service_account_email = element(split("/", var.execution_service_account), 3)

  # The final stage of the pipeline is production.
  last_target = var.targets[length(var.targets) - 1].name

  # Zero or one automation, keyed for for_each.
  automation = { for k, v in { main = var.automation } : k => v if v != null }
}

locals {
  # Exactly one of run_location / gke_cluster is set per target (enforced by
  # var.targets validation); compact() drops the unset one. require_approval
  # defaults to true on the last (production) target only.
  targets = { for t in var.targets : t.name => {
    description       = t.description
    deploy_parameters = t.deploy_parameters
    require_approval  = coalesce(t.require_approval, t.name == local.last_target)
    run               = formatlist("projects/%s/locations/%s", data.google_project.current.project_id, compact([t.run_location]))
    gke               = compact([t.gke_cluster])
  } }
}
