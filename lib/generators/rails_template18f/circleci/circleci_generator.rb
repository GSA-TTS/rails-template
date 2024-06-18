# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class CircleciGenerator < ::Rails::Generators::Base
      include Base
      include PipelineOptions

      desc <<~DESC
        Description:
          Install CircleCI pipeline files
      DESC

      def install_needed_gems
        gem_name = "rspec_junit_formatter"
        return if gem_installed? gem_name
        gem gem_name, "~> 0.6", group: :test
        bundle_install
      end

      def install_pipeline
        directory "circleci", ".circleci"
        copy_file "docker-compose.ci.yml"
        template "Dockerfile.ci"
        copy_file "bin/ci-server-start", mode: :preserve
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
    System_Ext(github, "GitHub", "GSA-controlled code repository")
    System_Ext(circleci, "CircleCI", "Continuous Integration Service")
EOB
        insert_into_file boundary_filename, <<~EOB, before: "@enduml"
          Rel(developer, github, "Publish code", "git ssh (22)")
          Rel(github, circleci, "Commit hook notifies CircleCI to run CI/CD pipeline", "https POST (443)")
          Rel(circleci, cg_api, "Deploy App", "Auth: SpaceDeployer Service Account, https (443)")
        EOB
      end

      def update_oscal_docs
        update_cicd_oscal_docs("CircleCI")
      end

      no_tasks do
        def readme_cicd
          <<~EOM

            CircleCI is used to run all tests and scans as part of pull requests.

            Security scans are also run on a daily schedule.
          EOM
        end

        def readme_staging_deploy
          <<~EOM

            Deploys to staging#{terraform? ? ", including applying changes in terraform," : ""} happen
            on every push to the `main` branch in GitHub.

            The following secrets must be set within [CircleCI Environment Variables](https://circleci.com/docs/2.0/env-vars/)
            to enable a deploy to work:

            | Secret Name | Description |
            | ----------- | ----------- |
            | `CF_STAGING_USERNAME` | cloud.gov SpaceDeployer username |
            | `CF_STAGING_PASSWORD` | cloud.gov SpaceDeployer password |
            | `RAILS_MASTER_KEY` | `config/master.key` |
            #{terraform_secret_values}
          EOM
        end

        def readme_prod_deploy
          <<~EOM

            Deploys to production#{terraform? ? ", including applying changes in terraform," : ""} happen
            on every push to the `production` branch in GitHub.

            The following secrets must be set within [CircleCI Environment Variables](https://circleci.com/docs/2.0/env-vars/)
            to enable a deploy to work:

            | Secret Name | Description |
            | ----------- | ----------- |
            | `CF_PRODUCTION_USERNAME` | cloud.gov SpaceDeployer username |
            | `CF_PRODUCTION_PASSWORD` | cloud.gov SpaceDeployer password |
            | `PRODUCTION_RAILS_MASTER_KEY` | `config/credentials/production.key` |
            #{terraform_secret_values}
          EOM
        end

        def readme_credentials
          <<~EOM

            1. Store variables that must be secret using [CircleCI Environment Variables](https://circleci.com/docs/2.0/env-vars/)
            1. Add the appropriate `--var` addition to the `cf push` line on the deploy job
          EOM
        end
      end

      private

      def terraform_secret_values
        if terraform?
          <<~EOM
            | `AWS_ACCESS_KEY_ID` | Access key for terraform state bucket |
            | `AWS_SECRET_ACCESS_KEY` | Secret key for terraform state bucket |
          EOM
        end
      end
    end
  end
end
