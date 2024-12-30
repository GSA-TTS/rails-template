# Generators are not automatically loaded by Rails
require "generators/rails_template18f/active_storage/active_storage_generator"

RSpec.describe RailsTemplate18f::Generators::ActiveStorageGenerator, type: :generator do
  setup_active_storage_destination

  before { allow(generator).to receive(:rails_command) }

  it "configures a local clamav runner" do
    run_generator
    expect(file("Procfile.dev")).to contain(/^clamav: docker run --rm -p 9443:9443 ghcr.io\/gsa-tts\/clamav-rest\/clamav:latest$/)
  end

  it "creates the active_storage migration file" do
    expect(generator).to receive(:rails_command).with("generate rails_template18f:cloud_gov_config ", {abort_on_failure: false, inline: true})
    expect(generator).to receive(:rails_command).with("active_storage:install", {inline: true})
    run_generator
  end

  it "configures the s3 upload service" do
    run_generator
    expect(file("config/environments/production.rb")).to contain("config.active_storage.service = :amazon")
    expect(file("config/environments/ci.rb")).to contain("config.active_storage.service = :local")
    expect(file("config/storage.yml")).to contain(/^amazon:$/)
    expect(file("config/storage.yml")).to contain(/^  service: S3$/)
    expect(file("config/storage.yml")).to contain(/^  access_key_id: <%= CloudGovConfig.dig\(:s3, :credentials, :access_key_id\) %>$/)
    expect(file("config/storage.yml")).to contain(/^  secret_access_key: <%= CloudGovConfig.dig\(:s3, :credentials, :secret_access_key\) %>$/)
    expect(file("config/storage.yml")).to contain(/^  region: us-gov-west-1$/)
    expect(file("config/storage.yml")).to contain(/^  bucket: <%= CloudGovConfig.dig\(:s3, :credentials, :bucket\) %>$/)
  end

  it "installs gems" do
    run_generator
    expect(file("Gemfile")).to contain('gem "faraday", "~> 2.12"')
    expect(file("Gemfile")).to contain('gem "faraday-multipart", "~> 1.1"')
    expect(file("Gemfile")).to contain('gem "aws-sdk-s3", "~> 1.176"')
  end

  it "copies the file upload job and model" do
    expect(generator).to receive(:rails_command).with "generate migration CreateFileUploads file:attachment record:references{polymorphic} scan_status:string", Hash
    run_generator
    expect(file("app/models/file_upload.rb")).to exist
    expect(file("spec/models/file_upload_spec.rb")).to exist
    expect(file("app/jobs/file_scan_job.rb")).to exist
    expect(file("spec/jobs/file_scan_job_spec.rb")).to exist
  end

  it "configures the env var" do
    run_generator
    expect(file(".env")).to contain("CLAMAV_API_URL=https://localhost:9443")
    expect(file("terraform/app.tf")).to contain('CLAMAV_API_URL = "https://tmp-clamapi-${var.env}.apps.internal:61443"')
  end

  it "updates the boundary diagram" do
    run_generator
    expect(file("doc/compliance/apps/application.boundary.md")).to contain('Container(clamav, "File Scanning API", "ClamAV", "Internal application for scanning user uploads")')
    expect(file("doc/compliance/apps/application.boundary.md")).to contain('ContainerDb(app_s3, "File Storage", "AWS S3", "User-uploaded file storage")')
    expect(file("doc/compliance/apps/application.boundary.md")).to contain('Rel(app, app_s3, "reads/writes file data", "https (443)")')
  end

  it "creates a new ADR" do
    run_generator
    expect(file("doc/adr/0005-clamav-file-scanning.md")).to contain("# 5. ClamAV File Scanning")
  end

  it "adds the component to the component list" do
    run_generator
    expect(file("doc/compliance/oscal/trestle-config.yaml")).to contain("  - active_storage")
  end

  it "copies the component definition" do
    run_generator
    expect(file("doc/compliance/oscal/component-definitions/active_storage/component-definition.json")).to exist
  end
end
