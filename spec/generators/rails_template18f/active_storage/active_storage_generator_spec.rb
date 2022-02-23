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
end
