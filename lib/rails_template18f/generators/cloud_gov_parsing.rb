# frozen_string_literal: true

module RailsTemplate18f
  module Generators
    module CloudGovParsing
      extend ActiveSupport::Concern

      private

      def cloud_gov_organization
        if terraform_dir_exists?
          staging_main = file_content("terraform/staging/main.tf")
          if (matches = staging_main.match(/cf_org_name\s+= "(?<org_name>.*)"/))
            return matches[:org_name]
          end
        end
        "TKTK-cloud.gov-org-name"
      end

      def cloud_gov_staging_space
        if terraform_dir_exists?
          staging_main = file_content("terraform/staging/main.tf")
          if (matches = staging_main.match(/cf_space_name\s+= "(?<space_name>.*)"/))
            return matches[:space_name]
          end
        end
        "staging"
      end

      def cloud_gov_production_space
        if terraform_dir_exists?
          prod_main = file_content("terraform/production/main.tf")
          if (matches = prod_main.match(/cf_space_name\s+= "(?<space_name>.*)"/))
            return matches[:space_name]
          end
        end
        "prod"
      end
    end
  end
end
