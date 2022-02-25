# frozen_string_literal: true

require "bundler"

module RailsTemplate18f
  module Generators
    module Base
      extend ActiveSupport::Concern
      include ::Rails::Generators::AppName

      class_methods do
        attr_accessor :source_path

        def source_root
          @source_root ||= File.expand_path("templates", File.dirname(source_path))
        end
      end

      included do
        self.source_path = RailsTemplate18f::Generators.const_source_location(name).first
      end

      private

      def bundle_install
        Bundler.with_original_env do
          in_root do
            run "bundle install"
            yield if block_given?
          end
        end
      end

      def gem_installed?(gem_name)
        file_content("Gemfile").match?(/gem "#{gem_name}"/)
      end

      def file_content(filename)
        file_path = File.expand_path(filename, destination_root)
        if File.exist? file_path
          File.read(file_path)
        else
          ""
        end
      end

      def ruby_version
        RUBY_VERSION
      end

      def terraform_dir_exists?
        Dir.exist? File.expand_path("terraform", destination_root)
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
