# Generators are not automatically loaded by Rails
require "generators/rails_template18f/active_storage/active_storage_generator"

RSpec.describe RailsTemplate18f::Generators::ActiveStorageGenerator, type: :generator do
  setup_default_destination

  before { allow(generator).to receive(:rails_command) }

  it "configures a local clamav runner" do
    run_generator
    expect(file("Procfile.dev")).to contain(/^clamav: docker run --rm -p 9443:9443 ajilaag\/clamav-rest:20211229$/)
  end

  it "creates the active_storage migration file" do
    expect(generator).to receive(:rails_command).with "active_storage:install"
    run_generator
  end

  it "installs faraday" do
    run_generator
    expect(file("Gemfile")).to contain('gem "faraday", "~> 2.2"')
    expect(file("Gemfile")).to contain('gem "faraday-multipart", "~> 1.0"')
  end

  it "copies the file upload job and model" do
    run_generator
    expect(file("app/models/file_upload.rb")).to exist
    expect(file("spec/models/file_upload_spec.rb")).to exist
    expect(file("app/jobs/file_scan_job.rb")).to exist
    expect(file("spec/jobs/file_scan_job_spec.rb")).to exist
  end

  it "configures the env var" do
    run_generator
    expect(file(".env")).to contain("CLAMAV_API_URL=https://localhost:9443/")
    expect(file("manifest.yml")).to contain("CLAMAV_API_URL: \"https://tmp-clamapi-((env)).apps.internal:9443/")
  end

  it "updates the boundary diagram" do
    run_generator
    expect(file("doc/compliance/apps/application.boundary.md")).to contain('Container(clamav, "File Scanning API", "ClamAV", "Internal application for scanning user uploads")')
    expect(file("doc/compliance/apps/application.boundary.md")).to contain('ContainerDb(app_s3, "File Storage", "AWS S3", "User-uploaded file storage")')
    expect(file("doc/compliance/apps/application.boundary.md")).to contain('Rel(app, app_s3, "reads/writes file data", "https (443)")')
  end

  it "updates the logical data model" do
    run_generator
    expect(file("doc/compliance/apps/data.logical.md")).to contain(generator.data_model_uml)
  end

  it "creates a new ADR" do
    run_generator
    expect(file("doc/adr/0005-clamav-file-scanning.md")).to contain("# 5. ClamAV File Scanning")
  end
end
