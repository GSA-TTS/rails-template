# Generators are not automatically loaded by Rails
require "generators/rails_template18f/newrelic/newrelic_generator"

RSpec.describe RailsTemplate18f::Generators::NewrelicGenerator, type: :generator do
  setup_default_destination

  before { run_generator }

  it "updates the CSP" do
    csp_file = "config/initializers/content_security_policy.rb"
    expect(file(csp_file)).to contain(/policy\.script_src .*"https:\/\/js-agent\.newrelic\.com", "https:\/\/\*\.nr-data\.net"/)
    expect(file(csp_file)).to contain('policy.connect_src :self, "https://*.nr-data.net"')
  end

  it "adds the newrelic gem" do
    expect(file("Gemfile")).to contain('gem "newrelic_rpm", "~> 9.16"')
  end

  it "creates the config file" do
    expect(file("config/newrelic.yml")).to exist
  end

  it "documents use in README" do
    expect(file("README.md")).to contain(generator.readme)
  end

  it "creates system entries in the boundary diagram" do
    boundary_file = "doc/compliance/apps/application.boundary.md"
    expect(file(boundary_file)).to contain("System_Ext(newrelic, \"New Relic\", \"Monitoring SaaS\")")
    expect(file(boundary_file)).to contain("Rel(app, newrelic, \"reports telemetry (ruby agent)\", \"tcp (443)\")")
    expect(file(boundary_file)).to contain("Rel(browser, newrelic, \"reports ux metrics (javascript agent)\", \"https (443)\")")
    expect(file(boundary_file)).to contain("Rel(developer, newrelic, \"Manage performance\", \"https (443)\")")
  end

  it "sets ENV var for deployed app" do
    expect(file("terraform/app.tf")).to contain('NEW_RELIC_LOG = "stdout"')
  end

  it "copies the new relic component" do
    expect(file("doc/compliance/oscal-component-definitions/newrelic/component-definition.json")).to exist
  end
end
