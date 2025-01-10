# Generators are not automatically loaded by Rails
require "generators/rails_template18f/i18n_js/i18n_js_generator"

RSpec.describe RailsTemplate18f::Generators::I18nJsGenerator, type: :generator do
  setup_default_destination

  before { run_generator }

  it "adds the i18n-js gem and config" do
    expect(file("Gemfile")).to contain('gem "i18n-js", "~> 4.2"')
    expect(file("Gemfile")).to contain('gem "listen", "~> 3.9"')
    expect(file("package.json")).to contain('"i18n-js":')
    expect(file("config/i18n-js.yml")).to contain("app/javascript/i18n/translations.json")
  end

  it "configures asset pipeline" do
    expect(file("lib/tasks/i18n.rake")).to exist
    expect(file("config/initializers/i18n_js.rb")).to exist
    expect(file("app/javascript/i18n/index.js")).to exist
  end
end
