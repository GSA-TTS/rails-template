# Generators are not automatically loaded by Rails
require "generators/rails_template18f/circleci/circleci_generator"

RSpec.describe RailsTemplate18f::Generators::CircleciGenerator, type: :generator do
  setup_default_destination

  context "no terraform actions" do
    before { run_generator }

    it "installs the junit formatting gem" do
      expect(file("Gemfile")).to contain(/gem "rspec_junit_formatter"/)
    end

    it "generates .circleci/config.yml" do
      expect(file(".circleci/config.yml")).to exist
      expect(file(".circleci/config.yml")).to_not contain("terraform")
    end

    it "installs supporting files for owasp scanning" do
      expect(file("bin/ci-server-start")).to exist
      expect(file("Dockerfile")).to exist
      expect(file("docker-compose.ci.yml")).to exist
    end

    it "documents use in README" do
      expect(file("README.md")).to contain(generator.readme_cicd)
      expect(file("README.md")).to contain(generator.readme_staging_deploy)
      expect(file("README.md")).to contain(generator.readme_prod_deploy)
      expect(file("README.md")).to contain(generator.readme_credentials)
    end

    it "creates system entries in the boundary diagram" do
      boundary_file = "doc/compliance/apps/application.boundary.md"
      expect(file(boundary_file)).to contain("System_Ext(github, \"GitHub\"")
      expect(file(boundary_file)).to contain("System_Ext(circleci, \"CircleCI\"")
      expect(file(boundary_file)).to contain("Rel(developer, github, \"Publish code\"")
      expect(file(boundary_file)).to contain("Rel(github, circleci, \"Commit hook notifies CircleCI to run CI/CD pipeline\"")
      expect(file(boundary_file)).to contain("Rel(circleci, cg_api, \"Deploy App\"")
    end

    it "updates the CA-7 control implementation" do
      expect(file("doc/compliance/oscal/dist/system-security-plans/lato/ca-7.md")).to contain(<<~EOS)
        ### tmp

        * tmp DevOps staff review OWASP and Dependency scans every build, or at least weekly.
        * tmp DevOps staff and the GSA ISSO review Web Application vulnerability scans on a weekly basis.
        * tmp Administrators and DevOps staff review changes for potential security impact and engage the tmp ISSO and ISSM who will review or engage assessment staff as needed.
      EOS
    end
  end

  context "with terraform" do
    before { run_generator %w[--terraform] }

    it "includes terraform actions in pipeline" do
      expect(file(".circleci/config.yml")).to contain("terraform_plan_staging")
      expect(file(".circleci/config.yml")).to contain("terraform_apply_staging")
      expect(file(".circleci/config.yml")).to contain("terraform_plan_production")
      expect(file(".circleci/config.yml")).to contain("terraform_apply_production")
    end
  end
end
