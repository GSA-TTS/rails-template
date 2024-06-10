# frozen_string_literal: true

module RailsTemplate18f
  module Generators
    module PipelineOptions
      extend ActiveSupport::Concern
      include CloudGovOptions

      included do
        class_option :terraform, type: :boolean, desc: "Generate actions for planning and applying terraform"
      end

      def terraform?
        options[:terraform].nil? ? terraform_dir_exists? : options[:terraform]
      end
    end
  end
end
