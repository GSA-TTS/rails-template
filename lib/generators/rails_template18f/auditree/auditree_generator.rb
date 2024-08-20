# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class AuditreeGenerator < ::Rails::Generators::Base
      include Base

      class_option :tag, desc: "Which auditree docker tag to use. Defaults to `latest`"
      class_option :git_email, desc: "Email address to associate with commits to the evidence locker"

      desc <<~DESC
        Description:
          Set up auditree validation checking with https://github.com/GSA-TTS/devtools-auditree.

          This generator is still experimental.
      DESC

      def copy_bin
        template "bin/auditree"
        chmod "bin/auditree", 0o755
      end

      def copy_github_actions
        if file_exists? ".github/workflows"
          directory "github", ".github"
        end
      end

      def update_readme
        if file_content("README.md").match?("## Documentation")
          insert_into_file "README.md", readme_contents, after: "## Documentation\n"
        else
          append_to_file "README.md", "\n## Documentation\n#{readme_contents}"
        end
      end

      def update_component_list
        if oscal_dir_exists?
          insert_into_file "doc/compliance/oscal/trestle-config.yaml", "  - devtools_cloud_gov\n"
        end
      end

      no_tasks do
        def docker_auditree_tag
          options[:tag].present? ? options[:tag] : "latest"
        end

        def git_email
          options[:git_email].present? ? options[:git_email] : "TKTK-email@gsa.gov"
        end

        def readme_contents
          <<~README

            ### Auditree Control Validation

            Auditree is used within CI/CD to validate that certain controls are in place.

            * Run `bin/auditree` to start the auditree CLI.
            * Run `bin/auditree SCRIPT_NAME` to run a single auditree script

            #### Initial auditree setup.

            These steps must happen once per project.

            1. Docker desktop must be running
            1. Initialize the config file with `bin/auditree init > config/auditree.template.json`
            1. Create an evidence locker repository with a default or blank README
            1. Create a github personal access token to interact with the code repo and evidence locker and set as `AUDITREE_GITHUB_TOKEN` secret within your production Github environment secrets.
            1. Update `config/auditree.template.json` with the repo addresses for your locker and code repos
            1. Copy the `devtools_cloud_gov` component definition into the project with the latest docker-trestle

            #### Ongoing use

            See the [auditree-devtools README](https://github.com/gsa-tts/auditree-devtools) for help with updating
            auditree and using new checks.
          README
        end
      end
    end
  end
end
