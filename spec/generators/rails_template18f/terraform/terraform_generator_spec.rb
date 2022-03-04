# Generators are not automatically loaded by Rails
require "generators/rails_template18f/terraform/terraform_generator"

RSpec.describe RailsTemplate18f::Generators::TerraformGenerator, type: :generator do
  setup_default_destination

  before { run_generator }

  it "creates the terraform directory" do
    expect(file("terraform/README.md")).to exist
  end

  it "creates the githook formatter" do
    expect(file(".githooks/pre-commit")).to contain(generator.githook_content)
  end

  it "updates the README" do
    expect(file("README.md")).to contain("Automatic linting and terraform formatting")
    expect(file("README.md")).to_not contain("Before the first deploy only")
    expect(file("README.md")).to contain("Follow the instructions in `terraform/README.md` to create the supporting services.")
  end

  it "adds jq to Brewfile" do
    expect(file("Brewfile")).to contain('brew "jq"')
  end
end
