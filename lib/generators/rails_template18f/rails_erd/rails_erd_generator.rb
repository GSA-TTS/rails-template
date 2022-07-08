# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class RailsErdGenerator < ::Rails::Generators::Base
      include Base

      desc <<~DESC
        Description:
          Install rails-erd and configure to automatically run on db migration
      DESC

      def install_graphviz
        append_to_file "Brewfile", <<~EOB

          # used by rails-erd documentation tool
          brew "graphviz"
        EOB
      end

      def install_gem
        return if gem_installed?("rails-erd")
        gem "rails-erd", "~> 1.7", group: :development
      end

      def install_helper_tasks
        bundle_install do
          generate "erd:install"
        end
      end

      def copy_config
        copy_file "erdconfig", ".erdconfig"
      end

      def update_readme
        insert_into_file "doc/compliance/README.md", <<~EOM, before: "## Development"
          ### Logical Data Model

          The logical data model will be auto-generated on each database migration.
          The rendered output is saved to doc/compliance/rendered/apps/data.logical.pdf

        EOM
      end
    end
  end
end
