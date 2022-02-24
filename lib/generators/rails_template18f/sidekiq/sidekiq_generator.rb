# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class SidekiqGenerator < ::Rails::Generators::Base
      include Base

      desc <<~DESC
        Description:
          Install Sidekiq and configure it as the ActiveJob backend
      DESC

      def install_gem
        gem "sidekiq", "~> 6.4"
      end

      def configure_server_runner
        append_to_file "Procfile.dev", "worker: bundle exec sidekiq\n"
        insert_into_file "manifest.yml", indent(<<~EOYAML), after: /processes:$\n/
          - type: worker
            instances: ((worker_instances))
            memory: ((worker_memory))
            command: bundle exec sidekiq
        EOYAML
        insert_into_file "manifest.yml", "\n  - #{app_name}-redis-((env))", after: "services:"
        inside "config/deployment" do
          append_to_file "staging.yml", <<~EOYAML
            worker_instances: 1
            worker_memory: 256M
          EOYAML
          append_to_file "production.yml", <<~EOYAML
            worker_instances: 1
            worker_memory: 512M
          EOYAML
        end
      end

      def configure_active_job
        copy_file "config/initializers/redis.rb"
        application "config.active_job.queue_adapter = :sidekiq"
      end

      def configure_sidekiq_ui
        prepend_to_file "config/routes.rb", "require \"sidekiq/web\"\n\n"
        route <<~EOR
          if Rails.env.development?
            mount Sidekiq::Web => "/sidekiq"
          end
        EOR
      end

      def update_boundary_diagram
        boundary_filename = "doc/compliance/apps/application.boundary.md"

        insert_into_file boundary_filename, indent(<<~EOB, 16), after: /ContainerDb\(app_db.*$\n/
          Container(worker, "<&layers> Sidekiq workers", "Ruby #{ruby_version}, Sidekiq", "Perform background work and data processing")
          ContainerDb(redis, "Redis Database", "AWS ElastiCache (Redis)", "Background job queue")
        EOB
        insert_into_file boundary_filename, <<~EOB, before: "@enduml"
          Rel(app, redis, "enqueue job parameters", "redis")
          Rel(worker, redis, "dequeues job parameters", "redis")
          Rel(worker, app_db, "reads/writes primary data", "psql (5432)")
        EOB
      end
    end
  end
end
