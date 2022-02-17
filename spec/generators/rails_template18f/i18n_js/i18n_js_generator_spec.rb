# Generators are not automatically loaded by Rails
require "generators/rails_template18f/i18n_js/i18n_js_generator"

RSpec.describe RailsTemplate18f::Generators::I18nJsGenerator, type: :generator do
  setup_default_destination

  before { run_generator }

  it "adds the i18n-js gem and config" do
    expect(file("Gemfile")).to contain('gem "i18n-js", "~> 3.9"')
    expect(file("package.json")).to contain('"i18n-js":')
    expect(file("config/i18n-js.yml")).to contain("app/assets/builds/translations.js")
  end

  it "configures asset pipeline" do
    expect(file("app/assets/config/manifest.js")).to contain("//= link i18n.js")
    expect(file("app/assets/config/manifest.js")).to contain("//= link translations.js")
    expect(file("app/views/layouts/application.html.erb")).to contain('<%= javascript_include_tag "i18n", "data-turbo-track": "reload" %>')
    expect(file("app/views/layouts/application.html.erb")).to contain('<%= javascript_include_tag "translations", "data-turbo-track": "reload" %>')
    expect(file("config/environments/development.rb")).to contain("config.middleware.use I18n::JS::Middleware")
    expect(file("lib/tasks/i18n.rake")).to exist
  end
end
