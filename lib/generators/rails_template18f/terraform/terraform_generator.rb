# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class TerraformGenerator < ::Rails::Generators::Base
      include Base
      include CloudGovOptions

      class_option :backend, default: "s3", desc: "Which terraform backend to use. Options: [s3, gitlab]"

      desc <<~DESC
        Description:
          Install terraform files for cloud.gov database and s3 services
      DESC

      def install
        directory "terraform", mode: :preserve
        chmod "terraform/terraform.sh", 0o755
      end

      def install_bootstrap
        if use_gitlab_backend?
          directory "gitlab_bootstrap", "terraform/bootstrap", mode: :preserve
        else
          directory "s3_bootstrap/common", "terraform/bootstrap", mode: :preserve
          if terraform_manage_spaces?
            template "s3_bootstrap/full/main.tf", "terraform/bootstrap/main.tf"
            copy_file "s3_bootstrap/full/imports.tf.tftpl", "terraform/bootstrap/templates/imports.tf.tftpl"
          else
            template "s3_bootstrap/sandbox/main.tf", "terraform/bootstrap/main.tf"
            copy_file "s3_bootstrap/sandbox/imports.tf.tftpl", "terraform/bootstrap/templates/imports.tf.tftpl"
          end
        end
        unless terraform_manage_spaces?
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

        def use_gitlab_backend?
          backend == "gitlab"
        end

        def backend
          options[:backend]
        end

        def backend_block
          if use_gitlab_backend?
            <<EOB
  backend "http" {
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }
EOB
          else
            <<EOB
  backend "s3" {
    encrypt           = true
    use_lockfile      = true
    use_fips_endpoint = true
    region            = "us-gov-west-1"
  }
EOB
          end
        end
      end
    end
  end
end
