# frozen_string_literal: true

require_relative "lib/rails_template_18f/version"

Gem::Specification.new do |spec|
  spec.name = "rails_template_18f"
  spec.version = RailsTemplate18f::VERSION
  spec.authors = ["Ryan Ahearn"]
  spec.email = ["ryan.ahearn@gsa.gov"]

  spec.summary = "TKTK: Write a short summary, because RubyGems requires one."
  spec.homepage = "https://github.com/18f/rails-template"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/18f/rails-template"
  spec.metadata["changelog_uri"] = "https://github.com/18f/rails-template/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.add_dependency "railties", "~> 7.0.0"

  spec.add_development_dependency "rspec", "~> 3.11"
  spec.add_development_dependency "ammeter", "~> 1.1"
  spec.add_development_dependency "standard", "~> 1.3"
end
