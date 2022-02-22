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
        append_to_file "Procfile.dev", "worker: bundle exec sidekiq"
        insert_into_file "manifest.yml", indent(<<~EOYAML), after: /processes:$\n/
          - type: worker
            instances: ((worker_instances))
            memory: ((worker_memory))
            command: bundle exec sidekiq
        EOYAML
        inside "config/deployment" do
          append_to_file "staging.yml", <<~EOYAML
            worker_instances: 1
            web_memory: 256M
          EOYAML
          append_to_file "production.yml", <<~EOYAML
            worker_instances: 1
            web_memory: 512M
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
    end
  end
end
