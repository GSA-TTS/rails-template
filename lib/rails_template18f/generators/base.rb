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

      private

      def file_content(filename)
        File.read(File.expand_path(filename, destination_root))
      end

      def ruby_version
        RUBY_VERSION
      end

      def skip_git?
        !Dir.exist?(File.expand_path(".git", destination_root))
      end

      def has_active_job?
        defined?(::ActiveJob)
      end

      def has_active_storage?
        defined?(::ActiveStorage)
      end
    end
  end
end
