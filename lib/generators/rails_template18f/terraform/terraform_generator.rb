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
        chmod "terraform/terraform.sh", 0o755
        if terraform_manage_spaces?
          template "full_bootstrap/main.tf", "terraform/bootstrap/main.tf"
          copy_file "full_bootstrap/imports.tf.tftpl", "terraform/bootstrap/templates/imports.tf.tftpl"
        else
          template "sandbox_bootstrap/main.tf", "terraform/bootstrap/main.tf"
          copy_file "sandbox_bootstrap/imports.tf.tftpl", "terraform/bootstrap/templates/imports.tf.tftpl"
          remove_file "terraform/bootstrap/users.auto.tfvars"
          remove_file "terraform/production.tfvars"
        end
      end

      def install_shadowenv
        append_to_file "Brewfile", <<~EOB

          # shadowenv for loading terraform backend secrets
          brew "shadowenv"
        EOB
        insert_into_file "README.md", indent("* [shadowenv](https://shopify.github.io/shadowenv/)\n"), after: /\* Install homebrew dependencies: `brew bundle`\n/
      end

      def ignore_files
        unless skip_git?
          append_to_file ".gitignore", <<~EOM

            # Terraform
            .terraform.lock.hcl
            **/.terraform/*
            secrets.*.tfvars
            terraform.tfstate
            terraform.tfstate.backup
            terraform/dist
          EOM
        end
      end

      def update_readme
        gsub_file "README.md", /^(### Automatic linting)\s*$/, '\1 and terraform formatting'
        gsub_file "README.md", /(ruby linting) (on every)/, '\1 and terraform formatting \2'
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
