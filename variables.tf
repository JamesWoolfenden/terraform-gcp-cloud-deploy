variable "name" {
  type        = string
  description = "Name of the delivery pipeline"

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", var.name))
    error_message = "var.name must be lowercase letters, digits or hyphens, start with a letter and be at most 63 characters"
  }
}

variable "location" {
  type        = string
  description = "Region the pipeline, targets and automation are created in"
  default     = "europe-west2"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "var.location must be a non-empty string"
  }
}

variable "description" {
  type        = string
  description = "Description of the delivery pipeline"
  default     = null

  validation {
    condition     = var.description == null || length(trimspace(var.description)) > 0
    error_message = "var.description must not be an empty string when set"
  }
}

variable "targets" {
  type = list(object({
    name              = string
    description       = optional(string)
    run_location      = optional(string)
    gke_cluster       = optional(string)
    require_approval  = optional(bool)
    profiles          = optional(list(string), [])
    deploy_parameters = optional(map(string), {})
  }))
  description = "Ordered list of targets; the pipeline promotes through them in this order. Set run_location (a region) for a Cloud Run target or gke_cluster (projects/P/locations/L/clusters/C) for a GKE target; GKE targets are reached on the internal IP and require var.worker_pool. require_approval defaults to true on the last target and false elsewhere"

  validation {
    condition     = length(var.targets) > 0
    error_message = "var.targets must contain at least one target"
  }

  validation {
    condition     = alltrue([for t in var.targets : (t.run_location == null) != (t.gke_cluster == null)])
    error_message = "each entry in var.targets must set exactly one of run_location or gke_cluster"
  }

  validation {
    condition     = length(distinct([for t in var.targets : t.name])) == length(var.targets)
    error_message = "var.targets names must be unique"
  }

  validation {
    condition     = alltrue([for t in var.targets : can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", t.name))])
    error_message = "var.targets names must be lowercase letters, digits or hyphens, starting with a letter"
  }

  validation {
    condition     = alltrue([for t in var.targets : !(can(regex("prod", t.name)) && t.require_approval == false)])
    error_message = "a target whose name contains \"prod\" must not set require_approval = false"
  }
}

variable "execution_service_account" {
  type        = string
  description = "ID (projects/PROJECT/serviceAccounts/EMAIL) of the dedicated service account Cloud Deploy render/deploy/verify jobs run as"

  validation {
    condition     = can(regex("^projects/[^/]+/serviceAccounts/[^/@]+@[^/]+$", var.execution_service_account))
    error_message = "var.execution_service_account must be a service account id of the form projects/PROJECT/serviceAccounts/EMAIL"
  }

  validation {
    condition     = !can(regex("(-compute@developer|@appspot|@cloudbuild)\\.gserviceaccount\\.com$", var.execution_service_account))
    error_message = "var.execution_service_account must not be a default GCP service account (Compute Engine, App Engine or Cloud Build)"
  }
}

variable "execution_service_account_roles" {
  type        = list(string)
  description = "Extra project roles for the execution SA so it can deploy to the runtime, e.g. roles/run.developer (Cloud Run) or roles/container.developer (GKE)"
  default     = []

  validation {
    condition     = alltrue([for r in var.execution_service_account_roles : !contains(["roles/owner", "roles/editor", "roles/viewer"], r)])
    error_message = "var.execution_service_account_roles must not contain basic roles (owner, editor, viewer)"
  }
}

variable "worker_pool" {
  type        = string
  description = "Private Cloud Build worker pool (projects/P/locations/L/workerPools/W) for Cloud Deploy jobs. Null uses the default pool"
  default     = null

  validation {
    condition     = var.worker_pool == null || can(regex("^projects/[^/]+/locations/[^/]+/workerPools/[^/]+$", var.worker_pool))
    error_message = "var.worker_pool must be null or of the form projects/P/locations/L/workerPools/W"
  }
}

variable "artifact_storage" {
  type        = string
  description = "GCS location (gs://bucket/path) for rendered manifests and logs. Null lets Cloud Deploy create a default bucket"
  default     = null

  validation {
    condition     = var.artifact_storage == null || can(regex("^gs://", var.artifact_storage))
    error_message = "var.artifact_storage must be null or a gs:// URI"
  }
}

variable "execution_timeout" {
  type        = string
  description = "Timeout for each Cloud Deploy job, e.g. \"3600s\""
  default     = "3600s"

  validation {
    condition     = can(regex("^[0-9]+s$", var.execution_timeout))
    error_message = "var.execution_timeout must be a duration such as \"3600s\""
  }
}

variable "automation" {
  type = object({
    service_account = string
    target_ids      = optional(list(string), ["*"])
    promote_wait    = optional(string, "0s")
  })
  description = "Optional Cloud Deploy automation that promotes successful releases to the next target. service_account is the email of a dedicated SA; it is granted clouddeploy.operator on this pipeline and actAs on the execution SA. Null disables automation"
  default     = null

  validation {
    condition     = var.automation == null || try(can(regex("^[^@]+@[^@]+\\.iam\\.gserviceaccount\\.com$", var.automation.service_account)), false)
    error_message = "var.automation.service_account must be a user-managed service account email"
  }

  validation {
    condition     = var.automation == null || try(can(regex("^[0-9]+s$", var.automation.promote_wait)), false)
    error_message = "var.automation.promote_wait must be a duration such as \"600s\""
  }
}

variable "releasers" {
  type        = list(string)
  description = "IAM members granted roles/clouddeploy.releaser on the pipeline and roles/iam.serviceAccountUser on the execution SA (both are needed to create releases)"
  default     = []

  validation {
    condition     = alltrue([for m in var.releasers : !contains(["allUsers", "allAuthenticatedUsers"], m)])
    error_message = "var.releasers must not contain allUsers or allAuthenticatedUsers"
  }

  validation {
    condition     = alltrue([for m in var.releasers : can(regex("^(user|serviceAccount|group|domain|principal|principalSet):.+", m))])
    error_message = "var.releasers entries must be IAM member strings such as group:EMAIL"
  }
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to the pipeline, targets and automation"
  default     = {}

  validation {
    condition     = alltrue([for k, v in var.labels : can(regex("^[a-z][a-z0-9_-]{0,62}$", k)) && can(regex("^[a-z0-9_-]{0,63}$", v))])
    error_message = "var.labels keys must start with a lowercase letter and keys/values must be lowercase alphanumerics, underscores, or hyphens, up to 63 characters (GCP label constraints)"
  }
}
