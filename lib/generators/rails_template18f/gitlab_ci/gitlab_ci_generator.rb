# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class GitlabCiGenerator < ::Rails::Generators::Base
      include Base
      include CloudGovOptions

      class_option :node_version, desc: "Node version to test against in actions"
      class_option :postgres_version, default: "15", desc: "PostgreSQL version "

      desc <<~DESC
        Description:
          Install GitLab CI workflow files
      DESC

      def install_actions
        template "gitlab-ci.yml", ".gitlab-ci.yml"
        directory "gitlab", ".gitlab"
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
    System_Ext(gitlabci, "GitLab w/ DevTools Runner", "GSA-controlled code repository and Continuous Integration Service")
EOB
        insert_into_file boundary_filename, <<~EOB, before: "@enduml"
          Rel(developer, gitlabci, "Publish code", "git ssh (22)")
          Rel(gitlabci, cg_api, "Deploy App", "Auth: SpaceDeployer Service Account, https (443)")
        EOB
      end

      no_tasks do
        def readme_cicd
          <<~EOM

            GitLab CI is used to run all tests and scans as part of pull requests.

            Security scans are also run on a scheduled basis. DEVELOPER TODO: create a pipeline schedule in the GitLab UI and update this sentence with the cadence.
          EOM
        end

        def readme_staging_deploy
          <<~EOM

            Deploys to staging happen via terraform on every push to the `main` branch in GitLab.

            The following secrets must be set within the masked and hidden [CI/CD variables](https://docs.gitlab.com/ci/variables/)

            | Secret Name | Description |
            | ----------- | ----------- |
            | `CF_USERNAME` | cloud.gov SpaceDeployer username |
            | `CF_PASSWORD` | cloud.gov SpaceDeployer password |
            | `RAILS_MASTER_KEY` | `config/master.key` |
          EOM
        end

        def readme_prod_deploy
          if terraform_manage_spaces?
            <<~EOM

              Deploys to production happen via terraform on every push to the `production` branch in GitLab.

              The following secrets must be set within the masked and hidden [CI/CD variables](https://docs.gitlab.com/ci/variables/)

              | Secret Name | Description |
              | ----------- | ----------- |
              | `CF_USERNAME` | cloud.gov SpaceDeployer username |
              | `CF_PASSWORD` | cloud.gov SpaceDeployer password |
              | `PRODUCTION_RAILS_MASTER_KEY` | `config/credentials/production.key`. Should be marked as `Protected`. |
            EOM
          else
            "Production deploys are not supported in the sandbox organization."
          end
        end

        def readme_credentials
          <<~EOM

            1. Store variables that must be secret using masked and hidden [CI/CD variables](https://docs.gitlab.com/ci/variables/) in GitLab
            1. Add the appropriate `-var` arguments to the `terraform:plan:<env>` and `terraform:apply:<env>` jobs like the existing `-var rails_master_key=`
          EOM
        end
      end

      private

      def postgres_version
        options[:postgres_version]
      end

      def node_version
        if options[:node_version].present?
          options[:node_version]
        elsif File.exist?(nvmrc_path)
          File.read(nvmrc_path).strip
        else
          "20.16"
        end
      end

      def node_major
        node_version.split(".").first
      end

      def nvmrc_path
        @nvmrc_path ||= File.expand_path(".nvmrc", destination_root)
      end
    end
  end
end
