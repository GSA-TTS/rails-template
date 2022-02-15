# Generators are not automatically loaded by Rails
require "generators/rails_template18f/dap/dap_generator"

RSpec.describe RailsTemplate18f::Generators::DapGenerator, type: :generator do
  setup_default_destination

  before { run_generator }

  it "updates the CSP" do
    csp_file = "config/initializers/content_security_policy.rb"
    expect(file(csp_file)).to contain(/policy\.img_src .*"https:\/\/www\.google-analytics\.com"/)
    expect(file(csp_file)).to contain(/policy\.script_src .*"https:\/\/dap\.digitalgov\.gov", "https:\/\/www\.google-analytics\.com"/)
    expect(file(csp_file)).to contain('policy.connect_src :self, "https://dap.digitalgov.gov", "https://www.google-analytics.com"')
  end

  it "installs a js snippet in application.html" do
    expect(file("app/views/layouts/application.html.erb")).to contain "javascript_include_tag \"https://dap.digitalgov.gov/Universal-Federated-Analytics-Min.js?agency=GSA\""
  end

  it "documents use in README" do
    expect(file("README.md")).to contain(generator.readme)
  end

  it "creates system entries in the boundary diagram" do
    boundary_file = "doc/compliance/apps/application.boundary.md"
    expect(file(boundary_file)).to contain("System_Ext(dap, \"DAP\", \"Analytics collection\")")
    expect(file(boundary_file)).to contain("Rel(browser, dap, \"reports usage\", \"https (443)\")")
    expect(file(boundary_file)).to contain("Rel(developer, dap, \"View traffic statistics\", \"https GET (443)\")")
  end
end
