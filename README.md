# terraform-gcp-cloud-deploy

[![Build Status](https://github.com/JamesWoolfenden/terraform-gcp-cloud-deploy/workflows/Verify/badge.svg?branch=main)](https://github.com/JamesWoolfenden/terraform-gcp-cloud-deploy/actions)
[![Latest Release](https://img.shields.io/github/release/JamesWoolfenden/terraform-gcp-cloud-deploy.svg)](https://github.com/JamesWoolfenden/terraform-gcp-cloud-deploy/releases/latest)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/tag/JamesWoolfenden/terraform-gcp-cloud-deploy.svg?label=latest)](https://github.com/JamesWoolfenden/terraform-gcp-cloud-deploy/releases/latest)
![Terraform Version](https://img.shields.io/badge/tf-%3E%3D1.5.0-blue.svg)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

Terraform module for a Cloud Deploy delivery pipeline. Targets (Cloud Run or GKE) are created from an ordered list and wired into a `serial_pipeline` in that order. Every target runs its render/deploy/verify jobs as a dedicated execution service account (granted `roles/clouddeploy.jobRunner`), optionally on a private Cloud Build worker pool, and the last (production) target requires approval by default. An optional `google_clouddeploy_automation` promotes successful releases to the next target, with its SA scoped to `roles/clouddeploy.operator` on this pipeline and `actAs` on the execution SA only.

## Usage

Add **module.cloud_deploy.tf** to your code:-

```terraform
module "cloud_deploy" {
  source                          = "jameswoolfenden/cloud-deploy/gcp"
  name                            = "example-app"
  location                        = "europe-west2"
  execution_service_account       = google_service_account.deploy.id
  execution_service_account_roles = ["roles/run.developer"]

  targets = [
    { name = "dev", run_location = "europe-west2" },
    { name = "staging", run_location = "europe-west2" },
    { name = "prod", run_location = "europe-west2", require_approval = true },
  ]
}
```

To deploy to Cloud Run, the execution SA also needs `roles/iam.serviceAccountUser` on each Cloud Run service's runtime SA, and whoever creates releases needs `roles/clouddeploy.releaser` (see `releasers`) and `actAs` on the execution SA. See [example/examplea](example/examplea) for a complete working example.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_clouddeploy_automation.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/clouddeploy_automation) | resource |
| [google_clouddeploy_delivery_pipeline.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/clouddeploy_delivery_pipeline) | resource |
| [google_clouddeploy_delivery_pipeline_iam_member.automation_operator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/clouddeploy_delivery_pipeline_iam_member) | resource |
| [google_clouddeploy_delivery_pipeline_iam_member.releasers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/clouddeploy_delivery_pipeline_iam_member) | resource |
| [google_clouddeploy_target.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/clouddeploy_target) | resource |
| [google_project_iam_member.execution_extra](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.execution_job_runner](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account_iam_member.automation_act_as](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_service_account_iam_member.releasers_act_as](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_project.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_artifact_storage"></a> [artifact\_storage](#input\_artifact\_storage) | GCS location (gs://bucket/path) for rendered manifests and logs. Null lets Cloud Deploy create a default bucket | `string` | `null` | no |
| <a name="input_automation"></a> [automation](#input\_automation) | Optional Cloud Deploy automation that promotes successful releases to the next target. service\_account is the email of a dedicated SA; it is granted clouddeploy.operator on this pipeline and actAs on the execution SA. Null disables automation | <pre>object({<br/>    service_account = string<br/>    target_ids      = optional(list(string), ["*"])<br/>    promote_wait    = optional(string, "0s")<br/>  })</pre> | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the delivery pipeline | `string` | `null` | no |
| <a name="input_execution_service_account"></a> [execution\_service\_account](#input\_execution\_service\_account) | ID (projects/PROJECT/serviceAccounts/EMAIL) of the dedicated service account Cloud Deploy render/deploy/verify jobs run as | `string` | n/a | yes |
| <a name="input_execution_service_account_roles"></a> [execution\_service\_account\_roles](#input\_execution\_service\_account\_roles) | Extra project roles for the execution SA so it can deploy to the runtime, e.g. roles/run.developer (Cloud Run) or roles/container.developer (GKE) | `list(string)` | `[]` | no |
| <a name="input_execution_timeout"></a> [execution\_timeout](#input\_execution\_timeout) | Timeout for each Cloud Deploy job, e.g. "3600s" | `string` | `"3600s"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels applied to the pipeline, targets and automation | `map(string)` | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | Region the pipeline, targets and automation are created in | `string` | `"europe-west2"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the delivery pipeline | `string` | n/a | yes |
| <a name="input_releasers"></a> [releasers](#input\_releasers) | IAM members granted roles/clouddeploy.releaser on the pipeline and roles/iam.serviceAccountUser on the execution SA (both are needed to create releases) | `list(string)` | `[]` | no |
| <a name="input_targets"></a> [targets](#input\_targets) | Ordered list of targets; the pipeline promotes through them in this order. Set run\_location (a region) for a Cloud Run target or gke\_cluster (projects/P/locations/L/clusters/C) for a GKE target; GKE targets are reached on the internal IP and require var.worker\_pool. require\_approval defaults to true on the last target and false elsewhere | <pre>list(object({<br/>    name              = string<br/>    description       = optional(string)<br/>    run_location      = optional(string)<br/>    gke_cluster       = optional(string)<br/>    require_approval  = optional(bool)<br/>    profiles          = optional(list(string), [])<br/>    deploy_parameters = optional(map(string), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_worker_pool"></a> [worker\_pool](#input\_worker\_pool) | Private Cloud Build worker pool (projects/P/locations/L/workerPools/W) for Cloud Deploy jobs. Null uses the default pool | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_automation_id"></a> [automation\_id](#output\_automation\_id) | ID of the automation, null when var.automation is null |
| <a name="output_pipeline_id"></a> [pipeline\_id](#output\_pipeline\_id) | ID of the delivery pipeline |
| <a name="output_pipeline_name"></a> [pipeline\_name](#output\_pipeline\_name) | Name of the delivery pipeline |
| <a name="output_target_ids"></a> [target\_ids](#output\_target\_ids) | Map of target name to target ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Role and Permissions

<!-- BEGINNING OF PRE-COMMIT-PIKE DOCS HOOK -->
The Terraform resource required is:

```golang
# apply role
resource "google_project_iam_custom_role" "terraform_pike" {
  project     = "pike-477416"
  role_id     = "terraform_pike"
  title       = "terraform_pike"
  description = "A user with least privileges"
  permissions = [
    "clouddeploy.automations.create",
    "clouddeploy.automations.delete",
    "clouddeploy.automations.get",
    "clouddeploy.automations.update",
    "clouddeploy.deliveryPipelines.create",
    "clouddeploy.deliveryPipelines.delete",
    "clouddeploy.deliveryPipelines.get",
    "clouddeploy.deliveryPipelines.getIamPolicy",
    "clouddeploy.deliveryPipelines.setIamPolicy",
    "clouddeploy.deliveryPipelines.update",
    "clouddeploy.targets.create",
    "clouddeploy.targets.delete",
    "clouddeploy.targets.get",
    "clouddeploy.targets.update",
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
    "resourcemanager.projects.get",
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy"
  ]
}

# plan role
resource "google_project_iam_custom_role" "terraform_pike_plan" {
  project     = "pike-477416"
  role_id     = "terraform_pike_plan"
  title       = "terraform_pike_plan"
  description = "A user with least privileges"
  permissions = [
    "clouddeploy.automations.get",
    "clouddeploy.deliveryPipelines.get",
    "clouddeploy.deliveryPipelines.getIamPolicy",
    "clouddeploy.targets.get",
    "iam.serviceAccounts.getIamPolicy",
    "resourcemanager.projects.get",
    "resourcemanager.projects.getIamPolicy"
  ]
}


```
<!-- END OF PRE-COMMIT-PIKE DOCS HOOK -->

## Help

**Got a question?**

File a GitHub [issue](https://github.com/jameswoolfenden/terraform-gcp-cloud-deploy/issues).

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/jameswoolfenden/terraform-gcp-cloud-deploy/issues) to report any bugs or file feature requests.

## Copyrights

Copyright © 2026 James Woolfenden

## License

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

See [LICENSE](LICENSE) for full details.

Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements. See the NOTICE file
distributed with this work for additional information
regarding copyright ownership. The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at

<https://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied. See the License for the
specific language governing permissions and limitations
under the License.

### Contributors

[![James Woolfenden][jameswoolfenden_avatar]][jameswoolfenden_homepage]<br/>[James Woolfenden][jameswoolfenden_homepage]

[jameswoolfenden_homepage]: https://github.com/jameswoolfenden
[jameswoolfenden_avatar]: https://github.com/jameswoolfenden.png?size=150
