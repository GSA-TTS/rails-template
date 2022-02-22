# Generators are not automatically loaded by Rails
require "generators/rails_template18f/clamav/clamav_generator"

RSpec.describe RailsTemplate18f::Generators::ClamavGenerator, type: :generator do
  setup_default_destination

  before { run_generator }

  it "configures a local runner" do
    expect(file("Procfile.dev")).to contain(/^clamav: docker run -p 9443:9443 ajilaag\/clamav-rest:20211229$/)
  end

  it "updates the boundary diagram" do
    expect(file("doc/compliance/apps/application.boundary.md")).to contain('Container(clamav, "File Scanning API", "ClamAV", "Internal application for scanning user uploads")')
    expect(file("doc/compliance/apps/application.boundary.md")).to contain('ContainerDb(app_s3, "File Storage", "AWS S3", "User-uploaded file storage")')
    expect(file("doc/compliance/apps/application.boundary.md")).to contain('Rel(app, app_s3, "reads/writes file data", "https (443)")')
  end
end
