# Generators are not automatically loaded by Rails
require "generators/rails_template18f/cloud_gov_config/cloud_gov_config_generator"

RSpec.describe RailsTemplate18f::Generators::CloudGovConfigGenerator, type: :generator do
  setup_default_destination

  before { run_generator }

  it "copies the CloudGovConfig model and test" do
    expect(file("app/models/cloud_gov_config.rb")).to exist
    expect(file("spec/models/cloud_gov_config_spec.rb")).to exist
  end
end
