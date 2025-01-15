# frozen_string_literal: true

require "rails/generators"
require "colorize"

module RailsTemplate18f
  module Generators
    class PublicEgressGenerator < ::Rails::Generators::Base
      include Base
      include CloudGovParsing

      desc <<~DESC
        Description:
          Install files for running cg-egress-proxy in <env>-egress cloud.gov spaces
          Prerequisite: the terraform generator has been run already
      DESC

      def check_terraform_exists
        unless terraform_dir_exists?
          fail "Run `rails g rails_template18f:terraform` before running this generator"
        end
      end

      def use_terraform_module
        append_to_file file_path("terraform/main.tf"), terraform_module
        append_to_file file_path("terraform/variables.tf"), <<~EOT
          variable "egress_allowlist" {
            type        = set(string)
            default     = []
            description = "The set of hostnames that the application is allowed to connect to"
          }
        EOT
        insert_into_file file_path("terraform/app.tf"), <<EOT, after: "environment = {\n"
    no_proxy                 = "apps.internal,s3-fips.us-gov-west-1.amazonaws.com"
EOT
        insert_into_file file_path("terraform/app.tf"), <<EOT, after: "service_bindings = [\n"
    { service_instance = "egress-proxy-${var.env}-credentials" },
EOT
        insert_into_file file_path("terraform/app.tf"), <<EOT, after: "depends_on = [\n"
    cloudfoundry_service_instance.egress_proxy_credentials,
EOT
      end

      def setup_proxy_vars
        create_file ".profile", <<~EOP unless file_exists?(".profile")
          ##
          # Cloud Foundry app initialization script
          # https://docs.cloudfoundry.org/devguide/deploy-apps/deploy-app.html#profile
          ##

        EOP
        insert_into_file ".profile", <<~EOP
          proxy_creds=$(echo "$VCAP_SERVICES" | jq --arg service_name "egress-proxy-$RAILS_ENV-credentials" '.[][] | select(.name == $service_name) | .credentials')
          export http_proxy=$(echo "$proxy_creds" | jq --raw-output ".http_uri")
          export https_proxy=$(echo "$proxy_creds" | jq --raw-output ".https_uri")
        EOP
      end

      def update_readme
        insert_into_file "README.md", readme_content, before: "## Documentation"
      end

      def update_boundary_diagram
        boundary_filename = "doc/compliance/apps/application.boundary.md"
        insert_into_file boundary_filename, <<EOB, after: "System_Boundary(inventory, \"Application\") {\n"
                Boundary(restricted_space, "Restricted egress space") {
                }
                Boundary(egress_space, "Public egress space") {
                    Container(proxy, "<&layers> Egress Proxy", "Caddy, cg-egress-proxy", "Proxy with allow-list of external connections")
                }
EOB
        insert_into_file boundary_filename, <<~EOB, before: "@enduml"
          Rel(app, proxy, "Proxy outbound connections", "https (443)")
        EOB
        puts "\n ================ TODO ================ \n".yellow
        puts "Update your application boundary to:"
        puts "1. Place application and services within the Restricted egress space"
        puts "2. Connect outbound connections through the egress proxy"
      end

      def update_oscal_doc
        copy_remote_oscal_component "cg-egress-proxy", "https://raw.githubusercontent.com/GSA-TTS/cg-egress-proxy/refs/heads/main/docs/compliance/component-definitions/cg-egress-proxy/component-definition.json"
      end

      no_tasks do
        def readme_content
          <<~README
            ### Public Egress Proxy

            Traffic to be delivered to the public internet must be proxied through the [cg-egress-proxy](https://github.com/GSA-TTS/cg-egress-proxy) app. Hostnames that the app should be able to
            reach should be added to the `egress_allowlist` terraform variable in `terraform/production.tfvars` and `terraform/staging.tfvars`

            See the [ruby troubleshooting doc](https://github.com/GSA-TTS/cg-egress-proxy/blob/main/docs/ruby.md) first if you have any problems making outbound connections through the proxy.
          README
        end

        def terraform_module
          <<~EOT

            module "egress_space" {
              source = "github.com/gsa-tts/terraform-cloudgov//cg_space?ref=v2.1.0"

              cf_org_name          = local.cf_org_name
              cf_space_name        = "${var.cf_space_name}-egress"
              allow_ssh            = var.allow_space_ssh
              deployers            = local.space_deployers
              developers           = var.space_developers
              security_group_names = ["public_networks_egress"]
            }

            module "egress_proxy" {
              source = "github.com/gsa-tts/terraform-cloudgov//egress_proxy?ref=v2.1.0"

              cf_org_name     = local.cf_org_name
              cf_egress_space = module.egress_space.space
              name            = "egress-proxy-${var.env}"
              allowlist       = var.egress_allowlist
              # depends_on line is needed only for initial creation and destruction. It should be commented out for updates to prevent unwanted cascading effects
              depends_on = [module.app_space, module.egress_space]
            }

            resource "cloudfoundry_network_policy" "egress_routing" {
              provider = cloudfoundry-community
              policy {
                source_app      = cloudfoundry_app.app.id
                destination_app = module.egress_proxy.app_id
                port            = "61443"
              }
              policy {
                source_app      = cloudfoundry_app.app.id
                destination_app = module.egress_proxy.app_id
                port            = "8080"
              }
            }

            resource "cloudfoundry_service_instance" "egress_proxy_credentials" {
              name        = "egress-proxy-${var.env}-credentials"
              space       = module.app_space.space_id
              type        = "user-provided"
              credentials = module.egress_proxy.json_credentials
              # depends_on line is needed only for initial creation and destruction. It should be commented out for updates to prevent unwanted cascading effects
              depends_on = [module.app_space]
            }
          EOT
        end
      end
    end
  end
end
