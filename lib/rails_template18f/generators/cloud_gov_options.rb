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

      def cloud_gov_organization
        return options[:cg_org] if options[:cg_org].present?
        super
      end

      def cloud_gov_staging_space
        return options[:cg_staging] if options[:cg_staging].present?
        super
      end

      def cloud_gov_production_space
        return options[:cg_prod] if options[:cg_prod].present?
        super
      end
    end
  end
end
