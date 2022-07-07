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
        class_option :oscal_profile, desc: "Name of the OSCAL profile to populate. Only needed if multiple folders are present in doc/compliance/oscal/dist/system-security-plans"
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

      def insert_into_oscal(filename, content, after: "## What is the solution and how is it implemented?\n")
        content = <<~EOS

          ### #{app_name}

          #{content}
        EOS
        begin
          insert_into_file File.join(oscal_path, filename), content, after: after
        rescue Thor::Error => ex
          warn ex.message
        end
      end

      def oscal_path
        @oscal_path ||= if options[:oscal_profile].present?
          file_path(File.join("doc/compliance/oscal/dist/system-security-plans", options[:oscal_profile]))
        else
          ssp_dir = file_path("doc/compliance/oscal/dist/system-security-plans")
          profiles = Dir.children(ssp_dir).select { |f| File.directory?(File.join(ssp_dir, f)) }
          if profiles.empty?
            fail "No OSCAL profiles found. Please run `make generate` from the `doc/compliance/oscal` folder"
          elsif profiles.count > 1
            fail "Multiple OSCAL profiles found. Please specify which one to update by passing the `--oscal-profile` option"
          else
            File.join(ssp_dir, profiles.first)
          end
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
