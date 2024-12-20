# Generators are not automatically loaded by Rails
require "generators/rails_template18f/github_actions/github_actions_generator"

RSpec.describe RailsTemplate18f::Generators::GithubActionsGenerator, type: :generator do
  setup_default_destination
  before { run_generator }

  it "documents use in README" do
    expect(file("README.md")).to contain(generator.readme_cicd)
    expect(file("README.md")).to contain(generator.readme_staging_deploy)
    expect(file("README.md")).to contain(generator.readme_prod_deploy)
    expect(file("README.md")).to contain(generator.readme_credentials)
  end

  it "does include test and deploy files" do
    expect(file(".github/workflows/rspec.yml")).to exist
    expect(file(".github/workflows/deploy-staging.yml")).to exist
    expect(file(".github/actions/setup-project/action.yml")).to exist
  end

  it "creates system entries in the boundary diagram" do
    expect(file("doc/compliance/apps/application.boundary.md")).to contain("System_Ext(githuball, \"GitHub w/ GitHub Actions\"")
    expect(file("doc/compliance/apps/application.boundary.md")).to contain("Rel(developer, githuball, \"Publish code\"")
    expect(file("doc/compliance/apps/application.boundary.md")).to contain("Rel(githuball, cg_api, \"Deploy App\"")
  end

  it "copies the component definition" do
    expect(file("doc/compliance/oscal-component-definitions/github_actions/component-definition.json")).to exist
  end

  it "creates a dependabot file" do
    expect(file(".github/dependabot.yml")).to exist
  end

  it "includes terraform-related actions" do
    expect(file(".github/workflows/terraform-staging.yml")).to exist
    expect(file(".github/workflows/terraform-production.yml")).to exist
  end

  it "includes terraform in the dependabot config" do
    expect(file(".github/dependabot.yml")).to contain("- package-ecosystem: terraform")
  end
end
