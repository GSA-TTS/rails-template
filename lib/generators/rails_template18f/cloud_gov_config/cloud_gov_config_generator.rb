# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class CloudGovConfigGenerator < ::Rails::Generators::Base
      include Base

      desc <<~DESC
        Description:
          Install a helper class to retrieve configuration from ENV["VCAP_SERVICES"]
      DESC

      def install_model_and_test
        copy_file "app/models/cloud_gov_config.rb"
        copy_file "spec/models/cloud_gov_config_spec.rb"
      end
    end
  end
end
