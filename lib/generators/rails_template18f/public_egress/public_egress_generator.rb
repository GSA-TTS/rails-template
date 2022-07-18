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

      def update_terraform_readme
        insert_into_file "terraform/README.md", <<~EOR, before: "\n## Set up a new environment manually"

          Passing the `-m` flag to `create_service_account.sh` is required for the account that will run terraform.
        EOR
        gsub_file "terraform/README.md", /(create_service_account.sh -s <SPACE_NAME> -u <ACCOUNT_NAME>)/, '\1 -m'
      end

      def use_space_module
        append_to_file file_path("terraform/staging/main.tf"), terraform_module
        append_to_file file_path("terraform/production/main.tf"), terraform_module
      end

      def create_default_acls
        %w[staging production].each do |env|
          create_file "config/deployment/egress_proxy/#{app_name}-#{env}.allow.acl", ""
          create_file "config/deployment/egress_proxy/#{app_name}-#{env}.deny.acl", ""
        end
      end

      def copy_deploy_script
        copy_file "deploy_egress_proxy.rb", "bin/ops/deploy_egress_proxy.rb", mode: :preserve
      end

      def add_to_deploy_steps
        if file_exists?(".github/workflows/deploy-staging.yml")
          append_to_file ".github/workflows/deploy-staging.yml", <<EOD
      - name: Deploy egress proxy
        run: ./bin/ops/deploy_egress_proxy.rb -s #{cloud_gov_staging_space} -a #{app_name}-staging
EOD
        end
        if file_exists?(".github/workflows/deploy-production.yml")
          append_to_file ".github/workflows/deploy-production.yml", <<EOD
      - name: Deploy egress proxy
        run: ./bin/ops/deploy_egress_proxy.rb -s #{cloud_gov_production_space} -a #{app_name}-production
EOD
        end
        if file_exists?(".circleci/config.yml")
          insert_into_file ".circleci/config.yml", <<EOD, before: "  deploy_production:"
      - run:
          name: Deploy egress proxy
          working_directory: bin/ops
          command: ./deploy_egress_proxy.rb -s #{cloud_gov_staging_space} -a #{app_name}-staging
EOD
          insert_into_file ".circleci/config.yml", <<EOD, after: "rails_master_key: PRODUCTION_RAILS_MASTER_KEY\n"
      - run:
          name: Deploy egress proxy
          working_directory: bin/ops
          command: ./deploy_egress_proxy.rb -s #{cloud_gov_production_space} -a #{app_name}-production
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

      def update_oscal_docs
        if oscal_dir_exists?
          insert_into_oscal "sc-7.md", <<~EOS, after: "## Implementation c.\n"
            #{app_name} is deployed to a restricted-egress cloud.gov space as described in [cloud.gov - controlling egress traffic](https://cloud.gov/docs/management/space-egress/).
            The restricted-egress space allows only communication to cloud.gov managed services including RDS.

            #{app_name} includes an egress proxy in a public-egress cloud.gov space. This proxy includes an allow-list of allowed external connections. All other
            connections are blocked.
          EOS
        end
      end

      no_tasks do
        def readme_content
          <<~README
            ### Public Egress Proxy

            Traffic to be delivered to the public internet or s3 must be proxied through the [cg-egress-proxy](https://github.com/GSA/cg-egress-proxy) app.

            To deploy the proxy:

            1. Ensure terraform state is up to date.
            1. Update the acl files in `config/deployment/egress_proxy`
            1. Ensure Docker Desktop is running
            1. Deploy the proxy to staging: `bin/ops/deploy_egress_proxy.rb -s #{cloud_gov_staging_space} -a #{app_name}-staging`
            1. Deploy the proxy to production: `bin/ops/deploy_egress_proxy.rb -s #{cloud_gov_production_space} -a #{app_name}-production`

          README
        end

        def terraform_module
          <<~EOT

            module "egress-space" {
              source = "../shared/egress_space"

              cf_user       = var.cf_user
              cf_password   = var.cf_password
              cf_org_name   = local.cf_org_name
              cf_space_name = local.cf_space_name
              # deployers should include any user or service account ID that will deploy the egress proxy
              deployers = [
                var.cf_user
              ]
            }
          EOT
        end
      end
    end
  end
end
