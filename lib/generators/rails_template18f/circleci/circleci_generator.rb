# frozen_string_literal: true

module RailsTemplate18f
  module Generators
    class CircleciGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::AppName
      include RailsTemplate18f::TerraformOptions

      desc <<~DESC
        Description:
          Install CircleCI pipeline files
      DESC

      def self.source_root
        @source_root ||= File.expand_path(File.join(File.dirname(__FILE__), "templates"))
      end

      def install_needed_gems
        gem "rspec_junit_formatter", "~> 0.5", group: :test
      end

      def install_pipeline
        directory "circleci", ".circleci"
        copy_file "docker-compose.ci.yml"
        template "Dockerfile"
        copy_file "bin/ci-server-start", mode: :preserve
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

            CircleCI is used to run all tests and scans as part of pull requests.

            Security scans are also run on a daily schedule.
          EOM
        end

        def readme_staging_deploy
          <<~EOM

            Deploys to staging#{terraform? ? ", including applying changes in terraform," : ""} happen
            on every push to the `main` branch in Github.

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
            on every push to the `production` branch in Github.

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
