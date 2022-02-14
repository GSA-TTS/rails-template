# frozen_string_literal: true

module RailsTemplate18f
  module Generators
    class GithubActionsGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::AppName

      class_option :cg_org, desc: "cloud.gov organization name"
      class_option :cg_staging, desc: "cloud.gov space name for staging"
      class_option :cg_prod, desc: "cloud.gov space name for production"
      class_option :terraform, type: :boolean, desc: "Generate actions for planning and applying terraform"
      class_option :node_version, desc: "Node version to test against in actions"

      desc <<~DESC
        Description:
          Install Github Actions workflow files
      DESC

      def self.source_root
        @source_root ||= File.expand_path("templates", __dir__)
      end

      def install_actions
        directory "github", ".github"
        if !terraform?
          remove_file ".github/workflows/terraform-staging.yml"
          remove_file ".github/workflows/terraform-production.yml"
        end
      end

      def update_readme
        insert_into_file "README.md", readme_cicd, after: "## CI/CD\n"
        insert_into_file "README.md", readme_staging_deploy, after: "#### Staging\n"
        insert_into_file "README.md", readme_prod_deploy, after: "#### Production\n"
        insert_into_file "README.md", readme_credentials, after: "#### Credentials and other Secrets\n"
      end

      no_tasks do
        def readme_cicd
          <<~EOM

            GitHub actions are used to run all tests and scans as part of pull requests.

            Security scans are also run on a scheduled basis. Weekly for static code scans, and daily for dependency scans.
          EOM
        end

        def readme_staging_deploy
          <<~EOM

            Deploys to staging#{terraform? ? ", including applying changes in terraform," : ""} happen
            on every push to the `main` branch in Github.

            The following secrets must be set within the `staging` [environment secrets](https://docs.github.com/en/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-an-environment)
            to enable a deploy to work:

            | Secret Name | Description |
            | ----------- | ----------- |
            | `CF_USERNAME` | cloud.gov SpaceDeployer username |
            | `CF_PASSWORD` | cloud.gov SpaceDeployer password |
            | `RAILS_MASTER_KEY` | `config/master.key` |
            #{terraform_secret_values}
          EOM
        end

        def readme_prod_deploy
          <<~EOM

            Deploys to production#{terraform? ? ", including applying changes in terraform," : ""} happen
            on every push to the `production` branch in Github.

            The following secrets must be set within the `production` [environment secrets](https://docs.github.com/en/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-an-environment)
            to enable a deploy to work:

            | Secret Name | Description |
            | ----------- | ----------- |
            | `CF_USERNAME` | cloud.gov SpaceDeployer username |
            | `CF_PASSWORD` | cloud.gov SpaceDeployer password |
            | `RAILS_MASTER_KEY` | `config/credentials/production.key` |
            #{terraform_secret_values}
          EOM
        end

        def readme_credentials
          <<~EOM

            1. Store variables that must be secret using [GitHub Environment Secrets](https://docs.github.com/en/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-an-environment)
            1. Add the secret to the `env:` block of the deploy action [as in this example](https://github.com/OHS-Hosting-Infrastructure/complaint-tracker/blob/a9e8d22aae2023a0afb631a6182251c04f597f7e/.github/workflows/deploy-stage.yml#L20)
            1. Add the appropriate `--var` addition to the `push_arguments` line on the deploy action [as in this example](https://github.com/OHS-Hosting-Infrastructure/complaint-tracker/blob/a9e8d22aae2023a0afb631a6182251c04f597f7e/.github/workflows/deploy-stage.yml#L27)
          EOM
        end
      end

      private

      def terraform_secret_values
        if terraform?
          <<~EOM
            | `TERRAFORM_STATE_ACCESS_KEY` | Access key for terraform state bucket |
            | `TERRAFORM_STATE_SECRET_ACCESS_KEY` | Secret key for terraform state bucket |
          EOM
        end
      end

      def ruby_version
        RUBY_VERSION
      end

      def node_version
        if options[:node_version].present?
          options[:node_version]
        elsif File.exist?(nvmrc_path)
          File.read(nvmrc_path).strip
        else
          "16.13"
        end
      end

      def nvmrc_path
        @nvmrc_path ||= File.expand_path(".nvmrc", destination_root)
      end

      def terraform?
        options[:terraform].nil? ? terraform_dir_exists? : options[:terraform]
      end

      def cloud_gov_organization
        if options[:cg_org].present?
          return options[:cg_org]
        elsif terraform_dir_exists?
          staging_main = File.read(terraform_path.join("staging", "main.tf"))
          if (matches = staging_main.match(/cf_org_name\s+= "(?<org_name>.*)"/))
            return matches[:org_name]
          end
        end
        "TKTK-cloud.gov-org-name"
      end

      def cloud_gov_staging_space
        if options[:cg_staging].present?
          return options[:cg_staging]
        elsif terraform_dir_exists?
          staging_main = File.read(terraform_path.join("staging", "main.tf"))
          if (matches = staging_main.match(/cf_space_name\s+= "(?<space_name>.*)"/))
            return matches[:space_name]
          end
        end
        "staging"
      end

      def cloud_gov_production_space
        if options[:cg_prod].present?
          return options[:cg_prod]
        elsif terraform_dir_exists?
          prod_main = File.read(terraform_path.join("production", "main.tf"))
          if (matches = prod_main.match(/cf_space_name\s+= "(?<space_name>.*)"/))
            return matches[:space_name]
          end
        end
        "prod"
      end

      def terraform_path
        Pathname.new File.expand_path("terraform", destination_root)
      end

      def terraform_dir_exists?
        Dir.exist? terraform_path
      end
    end
  end
end
