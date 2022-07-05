# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class OscalGenerator < ::Rails::Generators::Base
      include Base

      class_option :oscal_repo, required: true, desc: "GitHub Repo containing Compliance-Template fork"
      class_option :detach, type: :boolean, default: false, desc: "Copy OSCAL files into repo, rather than using a submodule"
      class_option :branch, desc: "Name of the branch to switch to when using a submodule. Defaults to `app_name`"

      desc <<~DESC
        Description:
          Add a fork of https://github.com/GSA-TTS/compliance-template.git as a
          submodule for documenting security controls.

          This generator is still experimental.

          Prerequisite:

          Fork the compliance-template repo for your own use. Updates to the documentation
          will be pushed to this fork, not the rails app repository.
      DESC

      def copy_template_files
        if detach?
          git clone: "#{options[:oscal_repo]} doc/compliance/oscal"
          remove_dir "doc/compliance/oscal/.git"
        else
          git submodule: "add #{options[:oscal_repo]} doc/compliance/oscal"
          inside "doc/compliance/oscal" do
            git switch: "-c #{branch_name}"
          end
        end
      end

      def update_readme
        if file_content("README.md").match?("## Documentation")
          insert_into_file "README.md", readme_contents, after: "## Documentation\n"
        else
          append_to_file "README.md", "\n## Documentation\n#{readme_contents}"
        end
      end

      no_tasks do
        def branch_name
          options[:branch].present? ? options[:branch] : app_name
        end

        def readme_contents
          if detach?
            <<~README

              ### Compliance Documentation

              Security Controls should be documented within doc/compliance/oscal.
            README
          else
            <<~README

              ### Compliance Documentation

              Security Controls should be documented within doc/compliance/oscal.

              See git's [submodule documentation](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
              for more information on tracking changes to these files.
            README
          end
        end

        def detach?
          options[:detach]
        end
      end
    end
  end
end
