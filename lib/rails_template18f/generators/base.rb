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
        if file_exists?(filename)
          File.read(file_path(filename))
        else
          ""
        end
      end

      def file_path(filename)
        File.expand_path(filename, destination_root)
      end

      def file_exists?(filename)
        File.exist? file_path(filename)
      end

      def ruby_version
        RUBY_VERSION
      end

      def oscal_dir_exists?
        Dir.exist? file_path("doc/compliance/oscal")
      end

      def copy_remote_oscal_component(component_name, cd_url)
        get cd_url, File.join(oscal_component_path, component_name, "component-definition.json")
        if oscal_dir_exists?
          insert_into_file "doc/compliance/oscal/trestle-config.yaml", "  - #{component_name}\n"
        end
      end

      def copy_oscal_component(component_name)
        template "oscal/component-definitions/#{component_name}/component-definition.json",
          File.join(oscal_component_path, component_name, "component-definition.json")
        if oscal_dir_exists?
          insert_into_file "doc/compliance/oscal/trestle-config.yaml", "  - #{component_name}\n"
        end
      end

      def oscal_component_path
        if oscal_dir_exists?
          file_path("doc/compliance/oscal/component-definitions")
        else
          file_path("doc/compliance/oscal-component-definitions")
        end
      end

      def terraform_dir_exists?
        Dir.exist? file_path("terraform")
      end

      def skip_git?
        !Dir.exist?(file_path(".git"))
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
