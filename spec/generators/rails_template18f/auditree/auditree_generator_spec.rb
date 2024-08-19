require "generators/rails_template18f/auditree/auditree_generator"

RSpec.describe RailsTemplate18f::Generators::AuditreeGenerator, type: :generator do
  setup_github_actions_destination

  subject! { run_generator }

  it "creates a helper script for running auditree" do
    expect(file("bin/auditree")).to exist
  end

  it "copies the auditree workflow files without overwriting exiting workflows" do
    expect(file(".github/workflows/auditree-validation.yml")).to exist
    expect(file(".github/actions/auditree-cmd/action.yml")).to exist
    expect(file(".github/workflows/deploy.yml")).to exist
  end
end
