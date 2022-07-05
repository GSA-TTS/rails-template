# Generators are not automatically loaded by Rails
require "generators/rails_template18f/github_actions/github_actions_generator"

RSpec.describe RailsTemplate18f::Generators::GithubActionsGenerator, type: :generator do
  context "no terraform actions" do
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

    it "does not include terraform-related actions" do
      expect(file(".github/workflows/terraform-staging.yml")).to_not exist
      expect(file(".github/workflows/terraform-production.yml")).to_not exist
    end

    it "creates system entries in the boundary diagram" do
      expect(file("doc/compliance/apps/application.boundary.md")).to contain("System_Ext(githuball, \"GitHub w/ GitHub Actions\"")
      expect(file("doc/compliance/apps/application.boundary.md")).to contain("Rel(developer, githuball, \"Publish code\"")
      expect(file("doc/compliance/apps/application.boundary.md")).to contain("Rel(githuball, cg_api, \"Deploy App\"")
    end

    it "updates the CA-7 control implementation" do
      expect(file("doc/compliance/oscal/dist/system-security-plans/lato/ca-7.md")).to contain(<<~EOS)
        **tmp Implementation:**

        * tmp DevOps staff review OWASP and Dependency scans every build, or at least weekly.
        * tmp DevOps staff and the GSA ISSO review Web Application vulnerability scans on a weekly basis.
        * tmp Administrators and DevOps staff review changes for potential security impact and engage the tmp ISSO and ISSM who will review or engage assessment staff as needed.
      EOS
    end
  end

  context "with terraform" do
    setup_terraform_destination
    before { run_generator }

    it "includes terraform-related actions" do
      expect(file(".github/workflows/terraform-staging.yml")).to exist
      expect(file(".github/workflows/terraform-production.yml")).to exist
    end

    it "documents use of .force-action-apply in terraform/README" do
      expect(file("terraform/README.md")).to contain(".force-action-apply")
    end
  end
end
