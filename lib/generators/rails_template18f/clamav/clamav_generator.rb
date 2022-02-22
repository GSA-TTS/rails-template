# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class ClamavGenerator < ::Rails::Generators::Base
      include Base

      desc <<~DESC
        Description:
          Document use of Clamav as ActiveStorage scanner
      DESC

      def configure_local_runner
        append_to_file "Procfile.dev", "clamav: docker run -p 9443:9443 ajilaag/clamav-rest:20211229"
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
    end
  end
end
