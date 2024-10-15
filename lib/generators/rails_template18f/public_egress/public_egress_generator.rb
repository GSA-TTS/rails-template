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
        append_to_file file_path("terraform/staging/main.tf"), terraform_module
        append_to_file file_path("terraform/production/main.tf"), terraform_module
      end

      def add_to_deploy_steps
        if file_exists?(".github/workflows/deploy-staging.yml")
          insert_into_file ".github/workflows/deploy-staging.yml", <<EOD, before: "      - name: Deploy app"
      - name: Set public egress
        uses: cloud-gov/cg-cli-tools@main
        with:
          cf_username: ${{ secrets.CF_USERNAME }}
          cf_password: ${{ secrets.CF_PASSWORD }}
          cf_org: #{cloud_gov_organization}
          cf_space: #{cloud_gov_staging_space}-egress
          cf_command: bind-security-group public_networks_egress $INPUT_CF_ORG --space $INPUT_CF_SPACE
EOD
        end
        if file_exists?(".github/workflows/deploy-production.yml")
          insert_into_file ".github/workflows/deploy-production.yml", <<EOD, before: "      - name: Deploy app"
      - name: Set public egress
        uses: cloud-gov/cg-cli-tools@main
        with:
          cf_username: ${{ secrets.CF_USERNAME }}
          cf_password: ${{ secrets.CF_PASSWORD }}
          cf_org: #{cloud_gov_organization}
          cf_space: #{cloud_gov_production_space}-egress
          cf_command: bind-security-group public_networks_egress $INPUT_CF_ORG --space $INPUT_CF_SPACE
EOD
        end
        if file_exists?(".circleci/config.yml")
          insert_into_file ".circleci/config.yml", <<EOD, before: "          name: Push application with deployment vars"
          name: Set public egress
          command: |
            cf bind-security-group public_networks_egress << parameters.cloudgov_org >> \
              --space << parameters.cloudgov_space >>-egress
        - run:
EOD
        end
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
              source = "github.com/gsa-tts/terraform-cloudgov//cg_space?ref=v1.1.0"

              cf_org_name   = local.cf_org_name
              cf_space_name = "${local.cf_space_name}-egress"
              # deployers should include any user or service account ID that will deploy the egress proxy
              deployers = [
                var.cf_user
              ]
            }

            module "egress_proxy" {
              source = "github.com/gsa-tts/terraform-cloudgov//egress_proxy?ref=v1.1.0"

              cf_org_name   = local.cf_org_name
              cf_space_name = module.egress_space.space_name
              client_space  = local.cf_space_name
              name          = "egress-proxy-${local.env}"
              # comment out allowlist if this module is being deployed before the app has ever been deployed
              allowlist = {
                "${local.app_name}-${local.env}" = []
              }
              # depends_on line is needed only for initial creation and destruction. It should be commented out for updates to prevent unwanted cascading effects
              depends_on = [module.app_space, module.egress_space]
            }
          EOT
        end
      end
    end
  end
end
