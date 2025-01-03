# frozen_string_literal: true

module RailsTemplate18f
  module Generators
    module CloudGovOptions
      extend ActiveSupport::Concern
      include CloudGovParsing

      included do
        class_option :cg_org, desc: "cloud.gov organization name"
        class_option :cg_staging, desc: "cloud.gov space name for staging"
        class_option :cg_prod, desc: "cloud.gov space name for production"
      end

      private

      def terraform_manage_spaces?
        # when operating in sandbox-gsa we can't use many features that rely
        # on being an OrgManager
        cloud_gov_organization != "sandbox-gsa"
      end

      def cloud_gov_organization
        @cloud_gov_organization ||= (options[:cg_org].present? ? options[:cg_org] : super)
      end

      def cloud_gov_staging_space
        @cloud_gov_staging_space ||= (options[:cg_staging].present? ? options[:cg_staging] : super)
      end

      def cloud_gov_production_space
        @cloud_gov_production_space ||= (options[:cg_prod].present? ? options[:cg_prod] : super)
      end
    end
  end
end
