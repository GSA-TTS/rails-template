# Generators are not automatically loaded by Rails
require "generators/rails_template18f/gitlab_ci/gitlab_ci_generator"

RSpec.describe RailsTemplate18f::Generators::GitlabCiGenerator, type: :generator do
  setup_default_destination
  before { run_generator }

  it "documents use in README" do
    expect(file("README.md")).to contain(generator.readme_cicd)
    expect(file("README.md")).to contain(generator.readme_staging_deploy)
    expect(file("README.md")).to contain(generator.readme_prod_deploy)
    expect(file("README.md")).to contain(generator.readme_credentials)
  end

  it "does include test and deploy files" do
    expect(file(".gitlab-ci.yml")).to exist
    expect(file(".gitlab/setup_langs.yml")).to exist
  end

  it "creates system entries in the boundary diagram" do
    expect(file("doc/compliance/apps/application.boundary.md")).to contain("System_Ext(gitlabci, \"GitLab w/ DevTools Runner\"")
    expect(file("doc/compliance/apps/application.boundary.md")).to contain("Rel(developer, gitlabci, \"Publish code\"")
    expect(file("doc/compliance/apps/application.boundary.md")).to contain("Rel(gitlabci, cg_api, \"Deploy App\"")
  end

  # it "includes terraform-related actions" do
  #   expect(file(".github/workflows/terraform-staging.yml")).to exist
  # end
end
