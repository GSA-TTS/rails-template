require "generators/rails_template18f/oscal/oscal_generator"

RSpec.describe RailsTemplate18f::Generators::OscalGenerator, type: :generator do
  setup_default_destination

  let(:ct_repo) { "git@github.com:GSA-TTS/compliance-template" }
  subject { run_generator ["--oscal_repo=#{ct_repo}", "-p"] }

  it "adds the submodule" do
    expect(subject).to match("git submodule add #{ct_repo} doc/compliance/oscal")
  end

  it "adds instructions to README" do
    expect(subject).to match(/insert\s+README\.md/)
  end
end
