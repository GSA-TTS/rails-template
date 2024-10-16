Rails.application.config.after_initialize do
  require "i18n-js/listen"
  # This will only run in development
  I18nJS.listen config_file: Rails.root.join("config/i18n-js.yml")
end
