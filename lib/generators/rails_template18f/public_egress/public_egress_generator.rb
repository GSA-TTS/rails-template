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
            reach should be added to the `allowlist` terraform configuration in `terraform/staging/main.tf` and `terraform/production/main.tf`

            See the [ruby troubleshooting doc](https://github.com/GSA-TTS/cg-egress-proxy/blob/main/docs/ruby.md) first if you have any problems making outbound connections through the proxy.
          README
        end

        def terraform_module
          <<~EOT

            module "egress_space" {
              source = "github.com/gsa-tts/terraform-cloudgov//cg_space?ref=v2.0.0"

              cf_org_name   = local.cf_org_name
              cf_space_name = "${var.cf_space_name}-egress"
              allow_ssh     = var.allow_space_ssh
              deployers     = local.space_deployers
              developers    = var.space_developers
            }
            # temporary method for setting egress rules until terraform provider supports it and cg_space module is updated
            data "external" "set-egress-space-egress" {
              program     = ["/bin/sh", "set_space_egress.sh", "-p", "-s", module.egress_space.space_name, "-o", local.cf_org_name]
              working_dir = path.module
              depends_on  = [module.egress_space]
            }

            module "egress_proxy" {
              source = "github.com/gsa-tts/terraform-cloudgov//egress_proxy?ref=v2.0.0"

              cf_org_name     = local.cf_org_name
              cf_egress_space = module.egress_space.space
              name            = "egress-proxy-${var.env}"
              allowlist = [
                # "host.to.allow"
              ]
              # depends_on line is needed only for initial creation and destruction. It should be commented out for updates to prevent unwanted cascading effects
              depends_on = [module.app_space, module.egress_space]
            }
          EOT
        end
      end
    end
  end
end
