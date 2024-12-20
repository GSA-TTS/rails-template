# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class GithubActionsGenerator < ::Rails::Generators::Base
      include Base
      include CloudGovOptions

      class_option :node_version, desc: "Node version to test against in actions"

      desc <<~DESC
        Description:
          Install GitHub Actions workflow files
      DESC

      def install_actions
        directory "github", ".github"
        if !oscal_dir_exists?
          remove_file ".github/workflows/validate-ssp.yml"
          remove_file ".github/workflows/assemble-ssp.yml"
        end
      end

      def update_readme
        if file_content("README.md").match?(/^## CI\/CD$/)
          insert_into_file "README.md", readme_cicd, after: "## CI/CD\n"
          insert_into_file "README.md", readme_staging_deploy, after: "#### Staging\n"
          insert_into_file "README.md", readme_prod_deploy, after: "#### Production\n"
          insert_into_file "README.md", readme_credentials, after: "#### Credentials and other Secrets\n"
        else
          append_to_file "README.md", <<~EOM
            ## CI/CD
            #{readme_cicd}

            ### Deployment

            #### Staging
            #{readme_staging_deploy}

            #### Production
            #{readme_prod_deploy}

            #### Credentials and other Secrets
            #{readme_credentials}
          EOM
        end
      end

      def update_boundary_diagram
        boundary_filename = "doc/compliance/apps/application.boundary.md"
        insert_into_file boundary_filename, <<EOB, after: "Boundary(cicd, \"CI/CD Pipeline\") {\n"
    System_Ext(githuball, "GitHub w/ GitHub Actions", "GSA-controlled code repository and Continuous Integration Service")
EOB
        insert_into_file boundary_filename, <<~EOB, before: "@enduml"
          Rel(developer, githuball, "Publish code", "git ssh (22)")
          Rel(githuball, cg_api, "Deploy App", "Auth: SpaceDeployer Service Account, https (443)")
        EOB
      end

      def update_oscal_docs
        copy_oscal_component "github_actions"
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

            Deploys to staging via terraform happen on every push to the `main` branch in GitHub.

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

            Deploys to production via terraform happen on every push to the `production` branch in GitHub.

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
            1. Add the appropriate `TF_VAR_<variable name>` addition to the `terraform-<env>.yml` and `deploy-<env>.yml` workflows like the existing `TF_VAR_rails_master_key`
          EOM
        end
      end

      private

      def terraform_secret_values
        <<~EOM
          | `TERRAFORM_STATE_ACCESS_KEY` | Access key for terraform state bucket |
          | `TERRAFORM_STATE_SECRET_ACCESS_KEY` | Secret key for terraform state bucket |
          | `TERRAFORM_STATE_BUCKET_NAME` | Bucket name for terraform state bucket |
        EOM
      end

      def node_version
        if options[:node_version].present?
          options[:node_version]
        elsif File.exist?(nvmrc_path)
          File.read(nvmrc_path).strip
        else
          "16.15"
        end
      end

      def nvmrc_path
        @nvmrc_path ||= File.expand_path(".nvmrc", destination_root)
      end
    end
  end
end
