# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class OscalGenerator < ::Rails::Generators::Base
      include Base

      class_option :oscal_repo, desc: "GitHub Repo to store compliance documents within. Leave blank to check docs into the app repo"
      class_option :tag, desc: "Which docker-trestle tag to use. Defaults to `latest`"
      class_option :branch, desc: "Name of the branch to switch to when using a submodule. Defaults to `main`"

      desc <<~DESC
        Description:
          Add a fork of https://github.com/GSA-TTS/compliance-template.git as a
          submodule for documenting security controls.

          This generator is still experimental.

          Prerequisite:

          Fork the compliance-template repo for your own use. Updates to the documentation
          will be pushed to this fork, not the rails app repository.
      DESC

      def configure_compliance_files
        if use_submodule?
          git submodule: "add #{options[:oscal_repo]} doc/compliance/oscal"
          inside "doc/compliance/oscal" do
            git switch: "-c #{branch_name}"
          end
        else
          create_file "doc/compliance/oscal/.keep"
        end
      end

      def copy_templates
        template "bin/trestle"
        chmod "bin/trestle", 0o755
        template "doc/compliance/oscal/trestle-config.yaml"
      end

      def update_readme
        if file_content("README.md").match?("## Documentation")
          insert_into_file "README.md", readme_contents, after: "## Documentation\n"
        else
          append_to_file "README.md", "\n## Documentation\n#{readme_contents}"
        end
      end

      def configure_submodule
        if use_submodule?
          git config: "-f .gitmodules submodule.\"doc/compliance/oscal\".branch #{branch_name}"
          git config: "diff.submodule log"
          git config: "status.submodulesummary 1"
          git config: "push.recurseSubmodules check"
        end
      end

      def configure_gitignore
        unless skip_git? || use_submodule?
          append_to_file ".gitignore", <<~EOM

            # Trestle working files
            doc/compliance/oscal/.trestle/_trash
            doc/compliance/oscal/.trestle/cache
          EOM
        end
      end

      no_tasks do
        def branch_name
          options[:branch].present? ? options[:branch] : "main"
        end

        def docker_trestle_tag
          options[:tag].present? ? options[:tag] : "latest"
        end

        def readme_contents
          content = <<~README

            ### Compliance Documentation

            Security Controls should be documented within doc/compliance/oscal.

            Run `bin/trestle` to start the trestle CLI.

            #### Initial trestle setup.

            These steps must happen once per project.

            1. Docker desktop must be running
            1. Start the trestle cli with `bin/trestle`
            1. Copy the `cloud_gov` component to the local workspace with `copy-component -n cloud_gov`
            1. Generate the initial markdown with `generate-ssp-markdown`

            #### Ongoing use

            See the [docker-trestle README](https://github.com/gsa-tts/docker-trestle) for help with the workflow
            for using those scripts for editing the SSP.
          README
          return content unless use_submodule?
          <<~README
            #{content}

            #### Git Submodule Commands

            See git's [submodule documentation](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
            for more information on tracking changes to these files.

            ##### Cloning this project

            `git clone --recurse-submodules <<REPO_ADDRESS>>`

            ##### Pull changes including OSCAL changes

            `git pull --recurse-submodules`

            ##### Push changes including OSCAL changes

            `git push --recurse-submodules=check` _then_ `git push --recurse-submodules=on-demand`

            ##### Helpful config settings:

            * `git config diff.submodule log`
            * `git config status.submodulesummary 1`
            * `git config push.recurseSubmodules check`
          README
        end

        def use_submodule?
          options[:oscal_repo].present?
        end
      end
    end
  end
end
