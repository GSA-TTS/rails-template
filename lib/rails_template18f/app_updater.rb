require "rails/app_updater"

module AppUpdaterOptions
  extend ActiveSupport::Concern

  class_methods do
    def generator_options
      options = super
      # These options all end up hardcoded to true in the default `rails app:update`
      options[:skip_active_job] = !defined?(ActiveJob::Railtie)
      options[:skip_action_mailbox] = !defined?(ActionMailbox::Engine)
      options[:skip_action_text] = !defined?(ActionText::Engine)
      options[:skip_test] = !defined?(Rails::TestUnitRailtie)
      options
    end
  end
end

Rails::AppUpdater.prepend(AppUpdaterOptions)
