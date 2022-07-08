# Generators are not automatically loaded by Rails
require "generators/rails_template18f/rails_erd/rails_erd_generator"

RSpec.describe RailsTemplate18f::Generators::RailsErdGenerator, type: :generator do
  setup_default_destination

  before { run_generator }

  it "adds the rails-erd gem" do
    expect(file("Gemfile")).to contain('gem "rails-erd", "~> 1.7"')
    expect(file("lib/tasks/auto_generate_diagram.rake")).to exist
  end

  it "adds graphviz to Brewfile" do
    expect(file("Brewfile")).to contain('brew "graphviz"')
  end

  it "copies the erdconfig file" do
    expect(file(".erdconfig")).to exist
  end

  it "updates the compliance README" do
    expect(file("doc/compliance/README.md")).to contain "The logical data model will be auto-generated on each database migration."
    expect(file("doc/compliance/README.md")).to contain "The rendered output is saved to doc/compliance/rendered/apps/data.logical.pdf"
  end
end
