# frozen_string_literal: true

module RailsTemplate18f
  module Generators
    module CloudGovParsing
      extend ActiveSupport::Concern

      private

      def cloud_gov_organization
        if terraform_dir_exists?
          main_tf = file_content("terraform/main.tf")
          if (matches = main_tf.match(/cf_org_name\s+= "(?<org_name>.*)"/))
            return matches[:org_name]
          end
        end
        "TKTK-cloud.gov-org-name"
      end

      def cloud_gov_staging_space
        if terraform_dir_exists?
          staging_vars = file_content("terraform/staging.tfvars")
          if (matches = staging_vars.match(/cf_space_name\s+= "(?<space_name>.*)"/))
            return matches[:space_name]
          end
        end
        "staging"
      end

      def cloud_gov_production_space
        if terraform_dir_exists?
          production_vars = file_content("terraform/production.tfvars")
          if (matches = production_vars.match(/cf_space_name\s+= "(?<space_name>.*)"/))
            return matches[:space_name]
          end
        end
        "production"
      end
    end
  end
end
