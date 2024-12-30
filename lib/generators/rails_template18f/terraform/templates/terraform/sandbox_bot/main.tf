terraform {
  required_version = "~> 1.10"
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry/cloudfoundry"
      version = "1.1.0"
    }
  }
  backend "local" {}
}
# empty config will let terraform borrow cf-cli's auth
provider "cloudfoundry" {}

variable "sandbox_name" {
  type        = string
  description = "Name of the sandbox environment we're deploying into"
}

locals {
  sa_service_name    = "${var.sandbox_name}-local-deployer"
  sa_key_name        = "deployer-access-key"
  sa_bot_credentials = jsondecode(data.cloudfoundry_service_credential_binding.runner_sa_key.credential_bindings.0.credential_binding).credentials
  sa_cf_username     = nonsensitive(local.sa_bot_credentials.username)
}

data "cloudfoundry_service_plans" "cg_service_account" {
  name                  = "space-deployer"
  service_offering_name = "cloud-gov-service-account"
}
data "terraform_remote_state" "bootstrap" {
  backend = "local"
  config = {
    path = "${path.module}/../bootstrap/terraform.tfstate"
  }
}
resource "cloudfoundry_service_instance" "runner_service_account" {
  name         = local.sa_service_name
  type         = "managed"
  space        = data.terraform_remote_state.bootstrap.outputs.mgmt_space_id
  service_plan = data.cloudfoundry_service_plans.cg_service_account.service_plans.0.id
}

resource "cloudfoundry_service_credential_binding" "runner_sa_key" {
  name             = local.sa_key_name
  service_instance = cloudfoundry_service_instance.runner_service_account.id
  type             = "key"
}
data "cloudfoundry_service_credential_binding" "runner_sa_key" {
  name             = local.sa_key_name
  service_instance = cloudfoundry_service_instance.runner_service_account.id
  depends_on       = [cloudfoundry_service_credential_binding.runner_sa_key]
}

data "cloudfoundry_user" "sa_user" {
  name = local.sa_cf_username
}
resource "cloudfoundry_org_role" "sa_org_manager" {
  user = data.cloudfoundry_user.sa_user.users.0.id
  type = "organization_manager"
  org  = data.terraform_remote_state.bootstrap.outputs.mgmt_org_id
}

resource "local_sensitive_file" "bot_secrets_file" {
  filename        = "${path.module}/../secrets.auto.tfvars"
  file_permission = "0600"

  content = <<-EOT
    # "${local.sa_service_name}"/"${local.sa_key_name}" generated by sandbox_bot terraform module.
    # Run `./run.sh ${var.sandbox_name} destroy` in that directory to clean up

    cf_user     = "${local.sa_cf_username}"
    cf_password = "${local.sa_bot_credentials.password}"
  EOT
}
