require "colorize"

## Supporting methods
# tell our template to grab all files from the templates directory
def source_paths
  ["#{__dir__}/templates"]
end

def skip_git?
  !!options[:skip_git]
end

def skip_active_job?
  !!options[:skip_active_job]
end

def webpack?
  adjusted_javascript_option == "webpack"
end

def hotwire?
  !options[:skip_hotwire]
end

def cloud_gov_org_tktk?
  @cloud_gov_organization =~ /TKTK/
end

@announcements = Hash.new { |h, k| h[k] = [] }
def register_announcement(section_name, instructions)
  @announcements[section_name.to_sym] << instructions
end

def print_announcements
  $stdout.puts "\n============= Post-install announcements ============= ".red unless @announcements.none?
  @announcements.each do |section_name, instructions|
    $stdout.puts "\n============= #{section_name} ============= ".yellow
    $stdout.puts instructions.join("\n")
  end
end

unless Gem::Dependency.new("rails", "~> 7.0.0").match?("rails", Rails.gem_version)
  warn "This template requires Rails 7.0.x"
  if Gem::Dependency.new("rails", "~> 6.1.0").match?("rails", Rails.gem_version)
    warn "See the rails-6 branch https://github.com/18f/rails-template/tree/rails-6"
  elsif Gem::Dependency.new("rails", "~> 7.1.0").match?("rails", Rails.gem_version)
    warn "Rails 7.1 is out! Please file an issue so we can get the template updated"
  else
    warn "We didn't recognize the version of Rails you are using: #{Rails.version}"
  end
  exit(1)
end

# ask setup questions
compliance_template = yes?("Include OSCAL files from compliance-template? (y/n)")
compliance_template_repo = "git@github.com:GSA-TTS/compliance-template.git"
compliance_template_submodule = compliance_template && yes?("Clone #{compliance_template_repo} as a git submodule? (y/n)")
if compliance_template_submodule
  compliance_template_repo = ask("What is the git clone address of your compliance-template fork?")
end

terraform = yes?("Create terraform files for cloud.gov services? (y/n)")
@cloud_gov_organization = ask("What is your cloud.gov organization name? (Leave blank to fill in later)")
default_staging_space = "staging"
cloud_gov_staging_space = ask("What is your cloud.gov staging space name? (Default: #{default_staging_space})")
default_prod_space = "prod"
cloud_gov_production_space = ask("What is your cloud.gov production space name? (Default: #{default_prod_space})")
@cloud_gov_organization = "TKTK-cloud.gov-org-name" if @cloud_gov_organization.blank?
cloud_gov_staging_space = default_staging_space if cloud_gov_staging_space.blank?
cloud_gov_production_space = default_prod_space if cloud_gov_production_space.blank?

@github_actions = yes?("Create GitHub Actions? (y/n)")
@circleci_pipeline = yes?("Create CircleCI config? (y/n)")
newrelic = yes?("Create FEDRAMP New Relic config files? (y/n)")
dap = yes?("If this will be a public site, should we include Digital Analytics Program code? (y/n)")
supported_languages = []
supported_languages.push(:es) if yes?("Add Spanish to supported locales, with starter es.yml? (y/n)")
supported_languages.push(:fr) if yes?("Add French to supported locales, with starter fr.yml? (y/n)")
supported_languages.push(:zh) if yes?("Add Simplified Chinese to supported locales, with starter zh.yml? (y/n)")

running_node_version = `node --version`.gsub(/^v/, "").strip
@node_version = ask("What version of NodeJS are you using? (Default: #{running_node_version})")
@node_version = running_node_version if @node_version.blank?

# copied from Rails' .ruby-version template implementation
@ruby_version = ENV["RBENV_VERSION"] || ENV["rvm_ruby_string"] || "#{RUBY_ENGINE}-#{RUBY_ENGINE_VERSION}"

run_db_setup = yes?("Run db setup steps? (y/n)")

## Start of app customizations
template "README.md", force: true
register_announcement("Documentation", <<~EOM)
  * Complete the project README by adding a quick summary of the project in the top section.
  * Review any TBD sections of the README and update where appropriate.
EOM

# ensure dependencies are installed
copy_file "Brewfile"
insert_into_file "bin/setup", <<EOSETUP, after: /Add necessary setup steps to this file.\n/
  puts "== Installing homebrew dependencies =="
  system("brew bundle --no-lock")
EOSETUP

# setup nvmrc
file ".nvmrc", @node_version

## Get files from Open Source Policy
get "https://raw.githubusercontent.com/18F/open-source-policy/master/CONTRIBUTING.md"
get "https://raw.githubusercontent.com/18F/open-source-policy/master/LICENSE.md"

## setup near-production CI environment
inside "config" do
  copy_file "environments/ci.rb"
  append_to_file "database.yml", <<~EOM

    ci:
      <<: *default
      # db will be configured by DATABASE_URL in CI. Use dev db here for ease of local use
      database: #{app_name}_development
  EOM
end

## setup near-production Staging environment
inside "config" do
  copy_file "environments/staging.rb"
  append_to_file "database.yml", <<~EOM

    staging:
      <<: *default
      # db will be configured by DATABASE_URL in a "real" staging env. Use dev db here for ease of local use
      database: #{app_name}_development
  EOM
end

## add x-config values to standard environment files
inside "config/environments" do
  insert_into_file "production.rb", "\n  config.x.show_demo_banner = false\n", before: /^end$/
  insert_into_file "development.rb", "\n  config.x.show_demo_banner = ENV[\"SHOW_DEMO_BANNER\"] == \"true\"\n", before: /^end$/
  insert_into_file "test.rb", "\n  config.x.show_demo_banner = false\n", before: /^end$/
end

# setup pa11y and owasp scanning
directory "bin", mode: :preserve
copy_file "pa11yci", ".pa11yci"
copy_file "editorconfig", ".editorconfig"
copy_file "zap.conf"
after_bundle do
  run "yarn add --dev pa11y-ci"
end

# updates for OWASP scan to pass
gem "secure_headers", "~> 6.3"
initializer "secure_headers.rb", <<~EOM
  SecureHeaders::Configuration.default do |config|
    # CSP settings are handled by Rails
    # see: content_security_policy.rb
    config.csp = SecureHeaders::OPT_OUT
  end
EOM
# Replace the default commented out block with our locked-down default
csp_initializer = "config/initializers/content_security_policy.rb"
style_policy = if hotwire?
  <<~EOM
    # 'unsafe-inline' is needed because Turbo uses inline CSS for at least the progress bar
    policy.style_src :self, "'unsafe-inline'"
  EOM
else
  "policy.style_src :self"
end

gsub_file csp_initializer, /^#   config.*\|policy\|$.+^#   end$/m, <<EOM
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src :self
    policy.form_action :self
    policy.frame_ancestors :none
    policy.img_src :self, :data
    policy.object_src :none
    policy.script_src :self
    policy.connect_src :self
    #{style_policy}
  end
EOM
# uncommenting the nonce generation lines is needed for any inline js we add
uncomment_lines csp_initializer, "Rails.application"
uncomment_lines csp_initializer, /end$/
uncomment_lines csp_initializer, "content_security_policy_nonce"

# install development & testing gems
gem_group :development, :test do
  gem "rspec-rails", "~> 5.1"
  gem "dotenv-rails", "~> 2.7"
  gem "brakeman", "~> 5.2"
  gem "bundler-audit", "~> 0.9"
  gem "standard", "~> 1.7"
end
if ENV["RT_DEV"] == "true"
  gem "rails_template_18f", group: :development, path: ENV["PWD"]
else
  gem "rails_template_18f", group: :development
end
after_bundle do
  gsub_file "bin/dev", /foreman start -f (.*)$/, <<~'EOM'
    # pass /dev/null for the environment file to prevent weird interactions between foreman and dotenv
    foreman start -e /dev/null -f \1
  EOM
end

copy_file "lib/tasks/scanning.rake"
copy_file "env", ".env"
copy_file "githooks/pre-commit", ".githooks/pre-commit", mode: :preserve

unless skip_git?
  after_bundle do
    rails_command "credentials:diff --enroll"
  end
  append_to_file ".gitignore", <<~EOM

    # Ignore Brewfile debug info
    Brewfile.lock.json

    # Ignore local dotenv overrides
    .env*.local

    # Ignore OWASP files
    /zap_report.html
    /zap.yaml

    # Ignore rspec examples status file
    spec/examples.txt
  EOM
end

# setup USWDS and asset pipeline
copy_file "browserslistrc", ".browserslistrc" if webpack?
after_bundle do
  run 'npm set-script build:css "postcss ./app/assets/stylesheets/application.postcss.scss -o ./app/assets/builds/application.css"'
  # include verbose flag for dev postcss output
  gsub_file "Procfile.dev", "yarn build:css --watch", "yarn build:css --verbose --watch"
  # Replace postcss-nesting with sass since USWDS uses sass
  run "yarn remove postcss-nesting"
  run "yarn add @csstools/postcss-sass postcss-scss postcss-minify"
  insert_into_file "postcss.config.js", "  syntax: 'postcss-scss',\n", before: /^\s+plugins/
  insert_into_file "package.json", <<-EOJSON, before: /^\s+\}$/
  },
  "resolutions": {
    "@csstools/postcss-sass/@csstools/sass-import-resolve": "https://github.com/rahearn/sass-import-resolve"
  EOJSON
  gsub_file "postcss.config.js", "postcss-nesting'),", <<~EOJS.strip
    @csstools/postcss-sass')({
          includePaths: ['./node_modules/@uswds/uswds/packages'],
        }),
  EOJS
  insert_into_file "postcss.config.js", "    process.env.NODE_ENV === 'production' ? require('postcss-minify') : null,\n", before: /^\s+\],/
  run "yarn add @uswds/uswds"
  appjs_file = "app/javascript/application.js"
  append_to_file appjs_file, "\nimport \"@uswds/uswds\"\n"
  if hotwire?
    append_to_file appjs_file, <<~EOJS

      // make sure USWDS components are wired to their behavior after a Turbo navigation
      import components from "@uswds/uswds/src/js/components"
      let initialLoad = true;
      document.addEventListener("turbo:load", () => {
        if (initialLoad) {
          // initial domready is handled by `import "uswds"` code
          initialLoad = false
          return
        }
        const target = document.body
        Object.keys(components).forEach((key) => {
          const behavior = components[key]
          behavior.on(target)
        })
      })
    EOJS
  end
  directory "app/assets"
  append_to_file "app/assets/stylesheets/application.postcss.css", <<~EOCSS
    @forward "uswds-settings.scss";
    @forward "uswds-components.scss";
  EOCSS
  inside "app/assets/stylesheets" do
    File.rename("application.postcss.css", "application.postcss.scss")
  end
  gsub_file "app/views/layouts/application.html.erb", "<html>", '<html lang="<%= I18n.locale %>">'
  gsub_file "app/views/layouts/application.html.erb", /^\s+<%= yield %>/, <<-EOHTML
    <%= render "application/usa_banner" %>
    <%= render "application/header" %>
    <main id="main-content">
      <div class="grid-container usa-section">
        <%= yield %>
      </div>
    </main>
  EOHTML
  append_to_file "config/initializers/assets.rb", "Rails.application.config.assets.paths << Rails.root.join(\"node_modules\")"
end
directory "app/views/application"

after_bundle do
  # install and configure RSpec
  generate "rspec:install"
  gsub_file "spec/spec_helper.rb", /^=(begin|end)$/, ""

  # Setup the PagesController and home (root) route
  generate :controller, "pages", "home", "--skip-routes", "--no-helper", "--no-assets"
  route "root 'pages#home'"

  gsub_file "spec/requests/pages_spec.rb", "/pages/home", "/"
  gsub_file "spec/views/pages/home.html.erb_spec.rb", "  pending \"add some examples to (or delete) \#{__FILE__}\"", <<-EOM
  it "displays the gov banner" do
    render template: "pages/home", layout: "layouts/application"
    expect(rendered).to match "An official website of the United States government"
  end
  EOM
end

# install ADRs and compliance documentation
directory "doc"
register_announcement("Documentation", <<~EOM)
  * Include a short description of your application in doc/compliance/apps/application.boundary.md
  * Remember to keep your Logical Data Model up to date in doc/compliance/apps/data.logical.md
EOM

if compliance_template
  after_bundle do
    generator_arguments = [
      "--oscal_repo=#{compliance_template_repo}",
      (compliance_template_submodule ? "--no-detach" : "--detach")
    ]
    generate "rails_template18f:oscal", *generator_arguments
  end
end

after_bundle do
  # Setup translations
  generate "rails_template18f:i18n", "--languages=#{supported_languages.join(",")}", "--force"
end

if newrelic
  after_bundle do
    generate "rails_template18f:newrelic"
  end
  register_announcement("New Relic", <<~EOM)
    A New Relic config file has been written to `config/newrelic.yml`

    See instructions in README to get started sending data to New Relic
  EOM
end

if dap
  after_bundle do
    generate "rails_template18f:dap"
  end
  register_announcement("Digital Analytics Program", "Update the DAP agency code in app/views/layouts/application.html.erb")
end

# infrastructure & deploy
template "manifest.yml"
copy_file "lib/tasks/cf.rake"
directory "config/deployment"

if terraform
  after_bundle do
    generator_arguments = [
      "--cg-org=#{@cloud_gov_organization}",
      "--cg-staging=#{cloud_gov_staging_space}",
      "--cg-prod=#{cloud_gov_production_space}"
    ]
    generate "rails_template18f:terraform", *generator_arguments
  end
  if cloud_gov_org_tktk?
    register_announcement("Terraform", <<~EOM)
      Fill in the cloud.gov organization information in:
        * terraform/bootstrap/main.tf
        * terraform/staging/main.tf
        * terraform/production/main.tf
    EOM
  end
  register_announcement("Terraform", "Run the bootstrap script and update the appropriate CI/CD environment variables defined in the Deployment section of the README")
end

if !skip_active_job?
  after_bundle do
    generate "rails_template18f:sidekiq"
  end
end

if !skip_active_storage?
  after_bundle do
    generate "rails_template18f:active_storage"
  end
end

if @github_actions
  after_bundle do
    generator_arguments = [
      (terraform ? "--terraform" : "--no-terraform"),
      "--cg-org=#{@cloud_gov_organization}",
      "--cg-staging=#{cloud_gov_staging_space}",
      "--cg-prod=#{cloud_gov_production_space}"
    ]
    generate "rails_template18f:github_actions", *generator_arguments
  end
  if cloud_gov_org_tktk?
    register_announcement("GitHub Actions", <<~EOM)
      * Fill in the cloud.gov organization information in .github/workflows/deploy-staging.yml
    EOM
  end
  register_announcement("GitHub Actions", <<~EOM)
    * Create environment variable secrets for deploy users as defined in the Deployment section of the README
  EOM
end

if @circleci_pipeline
  after_bundle do
    generator_arguments = [
      (terraform ? "--terraform" : "--no-terraform"),
      "--cg-org=#{@cloud_gov_organization}",
      "--cg-staging=#{cloud_gov_staging_space}",
      "--cg-prod=#{cloud_gov_production_space}"
    ]
    generate "rails_template18f:circleci", *generator_arguments
  end
  register_announcement("CircleCI", <<~EOM)
    * Create project environment variables for deploy users as defined in the Deployment section of the README
  EOM
end

# setup production credentials file
require "rails/generators"
require "rails/generators/rails/encryption_key_file/encryption_key_file_generator"
require "rails/generators/rails/encrypted_file/encrypted_file_generator"
key_file_generator = Rails::Generators::EncryptionKeyFileGenerator.new
key_file_path = Pathname.new "config/credentials/production.key"
key_file_generator.add_key_file_silently key_file_path
key_file_generator.ignore_key_file_silently key_file_path
Rails::Generators::EncryptedFileGenerator.new.add_encrypted_file_silently("config/credentials/production.yml.enc", key_file_path, <<~EOYAML)
  # Used as the base secret for all MessageVerifiers in Rails, including the one protecting cookies.
  secret_key_base: #{SecureRandom.hex(64)}
EOYAML
register_announcement("Credentials", <<~EOM)
  Two credentials files and keys have been generated:

  * production
    * config/credentials/production.yml.enc
    * config/credentials/production.key
  * all other environments
    * config/credentials.yml.enc
    * config/master.key

  The contents of `config/master.key` should be shared with other developers running the application.
  The contents of `config/credentials/production.key` must be limited to those developers who are authorized to have access to production.
EOM

# ensure this is the very last step
after_bundle do
  if run_db_setup
    rails_command "db:create"
    rails_command "db:migrate"
  end

  # x86_64-linux is required to install gems on any linux system such as cloud.gov or CI pipelines
  run "bundle lock --add-platform x86_64-linux"

  # bring generated code into compliance with standard ruby: https://github.com/testdouble/standard
  gsub_file "config/environments/production.rb", "(STDOUT)", "($stdout)"
  gsub_file "config/puma.rb", /\) { (\S+) }/, ', \1)'
  run "bundle exec standardrb --fix"

  unless skip_git?
    run "cp .gitignore .cfignore"
    git add: "."
    git commit: "-a -m 'Initial commit'"
  end

  # Post-install announcements
  print_announcements
end
