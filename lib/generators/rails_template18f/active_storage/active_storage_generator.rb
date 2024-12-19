# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class ActiveStorageGenerator < ::Rails::Generators::Base
      include Base

      desc <<~DESC
        Description:
          Document use of Clamav as ActiveStorage scanner
      DESC

      def configure_active_storage
        generate "rails_template18f:cloud_gov_config", inline: true
        rails_command "active_storage:install", inline: true
        comment_lines "config/environments/production.rb", /active_storage\.service/
        insert_into_file "config/environments/production.rb", "\n  config.active_storage.service = :amazon", after: /active_storage\.service.*$/
        environment "config.active_storage.service = :local", env: "ci"
        append_to_file "config/storage.yml", <<~EOYAML

          amazon:
            service: S3
            access_key_id: <%= CloudGovConfig.dig(:s3, :credentials, :access_key_id) %>
            secret_access_key: <%= CloudGovConfig.dig(:s3, :credentials, :secret_access_key) %>
            region: us-gov-west-1
            bucket: <%= CloudGovConfig.dig(:s3, :credentials, :bucket) %>
        EOYAML
      end

      def install_gems
        faraday_installed = gem_installed?("faraday")
        middleware_installed = gem_installed?("faraday-multipart")
        sdk_installed = gem_installed?("aws-sdk-s3")
        return if faraday_installed && middleware_installed && sdk_installed
        gem "faraday", "~> 2.12" unless faraday_installed
        gem "faraday-multipart", "~> 1.1" unless middleware_installed
        unless sdk_installed
          gem_group :production do
            gem "aws-sdk-s3", "~> 1.176"
          end
        end
        bundle_install
      end

      def create_scanned_upload_model_and_job
        generate :migration, "CreateFileUploads", "file:attachment", "record:references{polymorphic}", "scan_status:string", inline: true
        migration_file = Dir.glob(File.expand_path(File.join("db", "migrate", "[0-9]*_*.rb"), destination_root)).grep(/\d+_create_file_uploads.rb$/).first
        unless migration_file.nil?
          gsub_file migration_file, ":scan_status", ":scan_status, null: false, default: \"uploaded\""
        end
        directory "app"
        directory "spec"
      end

      def configure_local_clamav_runner
        append_to_file "Procfile.dev", "clamav: docker run --rm -p 9443:9443 ajilaag/clamav-rest:20211229\n"
      end

      def configure_clamav_env_var
        append_to_file ".env", <<~EOM

          # CLAMAV_API_URL tells FileScanJob where to send files for virus scans
          CLAMAV_API_URL=https://localhost:9443
        EOM
        # insert_into_file "manifest.yml", "    CLAMAV_API_URL: \"https://#{app_name}-clamapi-((env)).apps.internal:9443\"\n", before: /^\s+processes:/
        # insert_into_file "manifest.yml", "\n  - #{app_name}-s3-((env))", after: "services:"
      end

      def update_boundary_diagram
        boundary_filename = "doc/compliance/apps/application.boundary.md"

        insert_into_file boundary_filename, indent(<<~EOB, 16), after: /ContainerDb\(app_db.*$\n/
          Container(clamav, "File Scanning API", "ClamAV", "Internal application for scanning user uploads")
          ContainerDb(app_s3, "File Storage", "AWS S3", "User-uploaded file storage")
        EOB
        insert_into_file boundary_filename, <<~EOB, before: "@enduml"
          Rel(app, app_s3, "reads/writes file data", "https (443)")
        EOB
        if has_active_job?
          insert_into_file boundary_filename, <<~EOB, before: "@enduml"
            Rel(worker, app_s3, "reads/writes file data", "https (443)")
            Rel(worker, clamav, "scans files", "https (9443)")
          EOB
        end
      end

      def generate_adr
        adr_dir = File.expand_path(File.join("doc", "adr"), destination_root)
        if Dir.exist? adr_dir
          @next_adr_id = `ls #{adr_dir} | tail -n 1 | awk -F '-' '{print $1}'`.strip.to_i + 1
          template "doc/adr/clamav.md", "doc/adr/#{"%04d" % @next_adr_id}-clamav-file-scanning.md"
        end
      end

      def update_oscal
        copy_oscal_component "active_storage"
      end
    end
  end
end
