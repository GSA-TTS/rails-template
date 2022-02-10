module RailsTemplate18f
  module Generators
    class CircleciGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::AppName

      class_option :cg_org, desc: "cloud.gov organization name"
      class_option :cg_staging, desc: "cloud.gov space name for staging"
      class_option :cg_prod, desc: "cloud.gov space name for production"
      class_option :terraform, type: :boolean, desc: "Generate actions for planning and applying terraform"

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
        insert_into_file "README.md", <<~EOM, after: "## CI/CD\n"

          CircleCI is used to run all tests and scans as part of pull requests.

          Security scans are also run on a daily schedule.
        EOM
        insert_into_file "README.md", <<~EOM, after: "#### Staging\n"

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
        insert_into_file "README.md", <<~EOM, after: "#### Production\n"

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
        insert_into_file "README.md", <<~EOM, after: "#### Credentials and other Secrets\n"

          1. Store variables that must be secret using [CircleCI Environment Variables](https://circleci.com/docs/2.0/env-vars/)
          1. Add the appropriate `--var` addition to the `cf push` line on the deploy job
        EOM
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

      def ruby_version
        RUBY_VERSION
      end

      def terraform?
        options[:terraform].nil? ? terraform_dir_exists? : options[:terraform]
      end

      def cloud_gov_organization
        if options[:cg_org].present?
          return options[:cg_org]
        elsif terraform_dir_exists?
          staging_main = File.read(Rails.root.join("terraform", "staging", "main.tf"))
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
          staging_main = File.read(Rails.root.join("terraform", "staging", "main.tf"))
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
          prod_main = File.read(Rails.root.join("terraform", "production", "main.tf"))
          if (matches = prod_main.match(/cf_space_name\s+= "(?<space_name>.*)"/))
            return matches[:space_name]
          end
        end
        "prod"
      end

      def terraform_dir_exists?
        Dir.exist? Rails.root.join("terraform")
      end
    end
  end
end
