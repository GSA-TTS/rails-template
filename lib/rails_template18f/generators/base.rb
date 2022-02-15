# frozen_string_literal: true

module RailsTemplate18f
  module Generators
    module Base
      extend ActiveSupport::Concern
      include ::Rails::Generators::AppName

      included do
        self.source_path = RailsTemplate18f::Generators.const_source_location(name).first
      end

      class_methods do
        attr_accessor :source_path

        def source_root
          @source_root ||= File.expand_path("templates", File.dirname(source_path))
        end
      end
    end
  end
end
