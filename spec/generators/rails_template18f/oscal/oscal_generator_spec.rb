require "generators/rails_template18f/oscal/oscal_generator"

RSpec.describe RailsTemplate18f::Generators::OscalGenerator, type: :generator do
  setup_default_destination

  let(:ct_repo) { "git@github.com:GSA-TTS/compliance-template" }

  context "submodule" do
    subject { run_generator ["--oscal_repo=#{ct_repo}", "-p"] }

    it "adds the submodule" do
      expect(subject).to match("git submodule add #{ct_repo} doc/compliance/oscal")
    end

    it "switches to a new branch" do
      expect(subject).to match("git switch -c main")
    end

    it "adds instructions to README" do
      expect(subject).to match(/insert\s+README\.md/)
    end
  end

  context "in-repo" do
    subject! { run_generator }

    it "creates the oscal folder" do
      expect(file("doc/compliance/oscal/.keep")).to exist
    end

    it "creates a helper script for running docker-trestle" do
      expect(file("bin/trestle")).to exist
    end

    it "creates a yaml file to configure docker-trestle" do
      expect(file("doc/compliance/oscal/trestle-config.yaml")).to contain("components:")
    end
  end
end
