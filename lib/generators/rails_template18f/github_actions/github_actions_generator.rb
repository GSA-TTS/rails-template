# frozen_string_literal: true

module RailsTemplate18f
  module Generators
    class GithubActionsGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::AppName
      include RailsTemplate18f::TerraformOptions

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
    end
  end
end
