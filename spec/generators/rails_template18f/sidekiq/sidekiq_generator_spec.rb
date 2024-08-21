# Generators are not automatically loaded by Rails
require "generators/rails_template18f/sidekiq/sidekiq_generator"

RSpec.describe RailsTemplate18f::Generators::SidekiqGenerator, type: :generator do
  setup_default_destination

  before {
    expect(generator).to receive(:generate).with("rails_template18f:cloud_gov_config", {inline: true})
    run_generator
  }

  it "adds the sidekiq gem" do
    expect(file("Gemfile")).to contain('gem "sidekiq", "~> 7.3"')
  end

  it "adds sidekiq to manifest and Procfile.dev" do
    expect(file("Procfile.dev")).to contain(/^worker: bundle exec sidekiq$/)
    expect(file("manifest.yml")).to contain("command: bundle exec sidekiq")
    expect(file("manifest.yml")).to contain(/^\s+- type: worker$/)
  end

  it "configures active job and redis" do
    expect(file("config/application.rb")).to contain("config.active_job.queue_adapter = :sidekiq")
    expect(file("config/initializers/redis.rb")).to exist
  end

  it "configures the ui routes" do
    expect(file("config/routes.rb")).to contain(/^\s*if Rails\.env\.development\?\n\s+mount Sidekiq::Web => "\/sidekiq"\n\s*end$/)
  end

  it "updates the boundary diagram" do
    expect(file("doc/compliance/apps/application.boundary.md")).to contain("Container(worker, \"<&layers> Sidekiq workers\", \"Ruby #{RUBY_VERSION}, Sidekiq\", \"Perform background work and data processing\")")
    expect(file("doc/compliance/apps/application.boundary.md")).to contain('ContainerDb(redis, "Redis Database", "AWS ElastiCache (Redis)", "Background job queue")')
    expect(file("doc/compliance/apps/application.boundary.md")).to contain('Rel(app, redis, "enqueue job parameters", "redis")')
    expect(file("doc/compliance/apps/application.boundary.md")).to contain('Rel(worker, redis, "dequeues job parameters", "redis")')
    expect(file("doc/compliance/apps/application.boundary.md")).to contain('Rel(worker, app_db, "reads/writes primary data", "psql (5432)")')
  end

  it "adds redis to Brewfile" do
    expect(file("Brewfile")).to contain('brew "redis"')
  end
end
