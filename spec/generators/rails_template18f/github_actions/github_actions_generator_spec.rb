# Generators are not automatically loaded by Rails
require "generators/rails_template18f/github_actions/github_actions_generator"

RSpec.describe RailsTemplate18f::Generators::GithubActionsGenerator, type: :generator do
  setup_default_destination

  context "no terraform actions" do
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

    it "does not include terraform-related actions" do
      expect(file(".github/workflows/terraform-staging.yml")).to_not exist
      expect(file(".github/workflows/terraform-production.yml")).to_not exist
    end
  end

  context "with terraform" do
    before { run_generator %w[--terraform] }

    it "includes terraform-related actions" do
      expect(file(".github/workflows/terraform-staging.yml")).to exist
      expect(file(".github/workflows/terraform-production.yml")).to exist
    end
  end
end
