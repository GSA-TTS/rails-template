# Generators are not automatically loaded by Rails
require "generators/rails_template18f/public_egress/public_egress_generator"

RSpec.describe RailsTemplate18f::Generators::PublicEgressGenerator, type: :generator do
  context "no terraform folder" do
    setup_default_destination

    it "exits early" do
      expect { run_generator }.to raise_error("Run `rails g rails_template18f:terraform` before running this generator")
    end
  end

  context "terraform generator has been run" do
    setup_terraform_destination

    before { run_generator }

    it "adds the public-egress module" do
      expect(file("terraform/staging/main.tf")).to contain("module \"egress_space\" {")
      expect(file("terraform/production/main.tf")).to contain("module \"egress_space\" {")
    end

    it "adds instructions to the README" do
      expect(file("README.md")).to contain(generator.readme_content)
    end

    it "adds the proxy to the boundary diagram" do
      boundary_file = "doc/compliance/apps/application.boundary.md"
      expect(file(boundary_file)).to contain("Container(proxy, \"<&layers> Egress Proxy\"")
    end

    it "copies the oscal component-definition" do
      expect(file("doc/compliance/oscal-component-definitions/cg-egress-proxy/component-definition.json")).to exist
    end
  end
end