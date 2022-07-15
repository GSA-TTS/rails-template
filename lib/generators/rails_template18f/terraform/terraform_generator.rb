# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class TerraformGenerator < ::Rails::Generators::Base
      include Base
      include CloudGovOptions

      desc <<~DESC
        Description:
          Install terraform files for cloud.gov database and s3 services
      DESC

      def install
        directory "terraform", mode: :preserve
        chmod "terraform/create_service_account.sh", 0o755
        chmod "terraform/destroy_service_account.sh", 0o755
        chmod "terraform/set_space_egress.sh", 0o755
        chmod "terraform/bootstrap/run.sh", 0o755
        chmod "terraform/bootstrap/teardown_creds.sh", 0o755
      end

      def install_jq
        append_to_file "Brewfile", <<~EOB

          # used in terraform/create_service_account.sh
          brew "jq"
        EOB
        insert_into_file "README.md", indent("* [jq](https://stedolan.github.io/jq/)\n"), after: /\* Install homebrew dependencies: `brew bundle`\n/
      end

      def ignore_files
        unless skip_git?
          append_to_file ".gitignore", <<~EOM

            # Terraform
            .terraform.lock.hcl
            **/.terraform/*
            secrets.auto.tfvars
            terraform.tfstate
            terraform.tfstate.backup
          EOM
        end
      end

      def update_readme
        gsub_file "README.md", /^(### Automatic linting)\s*$/, '\1 and terraform formatting'
        gsub_file "README.md", /(ruby linting) (on every)/, '\1 and terraform formatting \2'
        gsub_file "README.md", /^Before the first deploy only.*$/, "Follow the instructions in `terraform/README.md` to create the supporting services."
      end

      def install_githook
        githook_file = ".githooks/pre-commit"
        if File.exist?(File.expand_path(githook_file, destination_root))
          append_to_file githook_file, "\n#{githook_content}"
        else
          create_file githook_file, <<~EOM
            #! /usr/bin/env bash
            #
            # This hook runs on `git commit` and will prevent you from committing without
            # approval from the linter and tests.
            #
            # To run, this file must be symlinked to:
            # .git/hooks/pre-commit
            #
            # To bypass this hook, run:
            # $ git commit --no-verify
            # $ git commit -n

            #{githook_content}
          EOM
          chmod githook_file, 0o755
        end
      end

      no_tasks do
        def githook_content
          <<~EOM
            echo "Running Terraform formatter"
            files=$(git diff --cached --name-only terraform)
            for f in $files
            do
              # Format any *.tf files that were cached/staged
              if [ -e "$f" ] && [[ $f == *.tf ]]; then
                terraform fmt "$f"
                git add "$f"
              fi
            done
          EOM
        end
      end
    end
  end
end
