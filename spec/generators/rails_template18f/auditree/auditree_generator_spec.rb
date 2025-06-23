require "generators/rails_template18f/auditree/auditree_generator"

RSpec.describe RailsTemplate18f::Generators::AuditreeGenerator, type: :generator do
  context "github actions" do
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

    it "update the trestle-config yaml file to include devtools_cloud_gov" do
      expect(file("doc/compliance/oscal/trestle-config.yaml")).to contain("  - devtools_cloud_gov")
    end
  end

  context "gitlab ci" do
    setup_gitlab_ci_destination

    subject! { run_generator }

    it "copes the auditree job file" do
      expect(file(".gitlab/auditree.yml")).to exist
      expect(file(".gitlab-ci.yml")).to contain('local: ".gitlab/auditree.yml"')
    end
  end
end
