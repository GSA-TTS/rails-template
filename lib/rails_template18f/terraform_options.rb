# frozen_string_literal: true

module RailsTemplate18f
  module TerraformOptions
    extend ActiveSupport::Concern

    included do
      class_option :cg_org, desc: "cloud.gov organization name"
      class_option :cg_staging, desc: "cloud.gov space name for staging"
      class_option :cg_prod, desc: "cloud.gov space name for production"
      class_option :terraform, type: :boolean, desc: "Generate actions for planning and applying terraform"
    end

    private

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
