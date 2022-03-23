# Generators are not automatically loaded by Rails
require "generators/rails_template18f/i18n/i18n_generator"

RSpec.describe RailsTemplate18f::Generators::I18nGenerator, type: :generator do
  setup_default_destination

  context "with default languages" do
    before { run_generator ["--force"] }

    it "adds the i18n tasks gem and config" do
      expect(file("Gemfile")).to contain('gem "i18n-tasks", "~> 1.0"')
      expect(file("config/i18n-tasks.yml")).to exist
      expect(file("spec/i18n_spec.rb")).to exist
    end

    it "adds translation files" do
      expect(file("config/locales/en.yml")).to exist
      expect(file("config/locales/es.yml")).to exist
      expect(file("config/locales/fr.yml")).to exist
      expect(file("config/locales/zh.yml")).to exist
    end

    it "adds routing code, helper, and around_action" do
      expect(file("config/routes.rb")).to contain("scope \"(:locale)\"")
      expect(file("app/helpers/application_helper.rb")).to contain("def format_active_locale(locale_string)")
      expect(file("app/controllers/application_controller.rb")).to contain("around_action :switch_locale")
    end
  end

  context "with only english" do
    before { run_generator ["--languages=", "--force"] }

    it "does not add routing code" do
      expect(file("config/routes.rb")).to_not contain("scope \"(:locale)\"")
    end

    it "adds only english translation file" do
      expect(file("config/locales/en.yml")).to exist
      expect(file("config/locales/es.yml")).to_not exist
      expect(file("config/locales/fr.yml")).to_not exist
      expect(file("config/locales/zh.yml")).to_not exist
    end
  end
end
