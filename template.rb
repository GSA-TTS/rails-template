require 'colorize'

## Supporting methods
# tell our template to grab all files from the templates directory
def source_paths
  ["#{__dir__}/templates"]
end

def skip_git?
  !!options[:skip_git]
end

def webpack?
  adjusted_javascript_option == "webpack"
end

def hotwire?
  !options[:skip_hotwire]
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
  $stderr.puts "This template requires Rails 7.0.x"
  if Gem::Dependency.new("rails", "~> 6.1.0").match?("rails", Rails.gem_version)
    $stderr.puts "See the rails-6 branch https://github.com/18f/rails-template/tree/rails-6"
  elsif Gem::Dependency.new("rails", "~> 7.1.0").match?("rails", Rails.gem_version)
    $stderr.puts "Rails 7.1 is out! Please file an issue so we can get the template updated"
  else
    $stderr.puts "We didn't recognize the version of Rails you are using: #{Rails.version}"
  end
  exit(1)
end

@terraform = yes?("Create terraform files for cloud.gov services? (y/n)")
@github_actions = yes?("Create Github Actions? (y/n)")
@circleci_pipeline = yes?("Create CircleCI config? (y/n)")
@adrs = yes?("Create initial Architecture Decision Records? (y/n)")
@newrelic = yes?("Create FEDRAMP New Relic config files? (y/n)")
@dap = yes?("If this will be a public site, should we include Digital Analytics Program code? (y/n)")
@supported_languages = [:en]
@supported_languages.push(:es) if yes?("Add Spanish to supported locales, with starter es.yml? (y/n)")
@supported_languages.push(:zh) if yes?("Add Simplified Chinese to supported locales, with starter zh.yml? (y/n)")

running_node_version = `node --version`.gsub(/^v/, "").strip
@node_version = ask("What version of NodeJS are you using? (Default: #{running_node_version})")
@node_version = running_node_version if @node_version.blank?

# copied from Rails' .ruby-version template implementation
@ruby_version = ENV["RBENV_VERSION"] || ENV["rvm_ruby_string"] || "#{RUBY_ENGINE}-#{RUBY_ENGINE_VERSION}"

run_db_setup = yes?("Run db setup steps? (y/n)")


## Start of app customizations
template "README.md", force: true
register_announcement("Documentation", <<EOM)
* Complete the project README by adding a quick summary of the project in the top section.
* Review any TBD sections of the README and update where appropriate.
EOM

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

script_policy = [":self"]
connect_policy = [":self"]
image_policy = [":self", ":data"]

if @newrelic
  script_policy << '"https://js-agent.newrelic.com"'
  script_policy << '"https://*.nr-data.net"'
  connect_policy << '"https://*.nr-data.net"'
end

if @dap
  image_policy << '"https://www.google-analytics.com"'
  script_policy << '"https://dap.digitalgov.gov"'
  script_policy << '"https://www.google-analytics.com"'
  connect_policy << '"https://dap.digitalgov.gov"'
  connect_policy << '"https://www.google-analytics.com"'
end

gsub_file csp_initializer, /^#   config.*\|policy\|$.+^#   end$/m, <<EOM
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src :self
    policy.form_action :self
    policy.frame_ancestors :none
    policy.img_src #{image_policy.join(", ")}
    policy.object_src :none
    policy.script_src #{script_policy.join(", ")}
    policy.connect_src #{connect_policy.join(", ")}
    #{style_policy}
  end
EOM
# uncommenting the nonce generation lines is needed for any inline js we add
uncomment_lines csp_initializer, "Rails.application"
uncomment_lines csp_initializer, /end$/
uncomment_lines csp_initializer, "content_security_policy_nonce"

if @newrelic
  gem "newrelic_rpm", "~> 8.3"
  copy_file "config/newrelic.yml"

  register_announcement("New Relic", <<~EOM)
    A New Relic config file has been written to `config/newrelic.yml`

    To get started sending metrics via New Relic APM:
    1. Replace `<APPNAME>` with what is registered for your application in New Relic
    2. Add your New Relic license key to the Rails credentials with key `new_relic_key`.
    3. Comment out the `agent_enabled: false` line

    To enable browser monitoring:
    4. Embed the Javascript snippet provided  by New Relic into `application.html.erb`.
    It is recommended to vary this based on environment  (i.e. include one snippet
    for staging and another for production).
  EOM
end

gem_group :development, :test do
  gem "rspec-rails", "~> 5.0"
  gem "dotenv-rails", "~> 2.7"
  gem "brakeman", "~> 5.2"
  gem "bundler-audit", "~> 0.9"
  gem "standard", "~> 1.5"
  gem "i18n-tasks", "~> 0.9"
  gem "rspec_junit_formatter", "~> 0.5" if @circleci_pipeline
end

copy_file "lib/tasks/scanning.rake"


unless skip_git?
  rails_command "credentials:diff --enroll"
  template "githooks/pre-commit", ".githooks/pre-commit"
  register_announcement("Git", <<~EOM)
    `.githooks/pre-commit` has been installed to run linters on each git commit
    To use, each developer must follow the instructions in the top of the file.
  EOM
  append_to_file ".gitignore", <<~EOM

    # Ignore local dotenv overrides
    .env*.local

    # Ignore OWASP files
    /zap_report.html
    /zap.yaml

    # Ignore rspec examples status file
    spec/examples.txt
  EOM
end

# Setup translations
@supported_languages.each do |language|
  copy_file "config/locales/#{language}.yml", force: true
end
application "config.i18n.available_locales = #{@supported_languages}"
application "config.i18n.fallbacks = [:en]"
after_bundle do
  # Recommended by i18n-tasks
  run "cp $(i18n-tasks gem-path)/templates/config/i18n-tasks.yml config/"
end

# setup USWDS
copy_file "browserslistrc", ".browserslistrc" if webpack?
uncomment_lines "Gemfile", "sassc-rails" # use sassc-rails for asset minification in prod
after_bundle do
  js_startup = if webpack?
    "webpack --config webpack.config.js"
  else
    "esbuild app/javascript/*.* --bundle --sourcemap --outdir=app/assets/builds"
  end
  insert_into_file "package.json", <<-EOJSON, before: /^\s+"dependencies"/
  "scripts": {
    "build": "#{js_startup}",
    "build:css": "postcss ./app/assets/stylesheets/application.postcss.css -o ./app/assets/builds/application.css"
  },
  EOJSON
  # Replace postcss-nesting with sass since USWDS uses sass
  run "yarn remove postcss-nesting"
  # include fork of @csstools/postcss-sass until that library is updated for postcss 8
  run "yarn add https://github.com/sinankeskin/postcss-sass"
  run "yarn add postcss-scss"
  insert_into_file "postcss.config.js", "  syntax: 'postcss-scss',\n", before: /^\s+plugins/
  gsub_file "postcss.config.js", "postcss-nesting", "@csstools/postcss-sass"
  run "yarn add uswds"
  appjs_file = "app/javascript/application.js"
  append_to_file appjs_file, "\nimport \"uswds\"\n"
  if hotwire?
    append_to_file appjs_file, <<~EOJS

      // make sure USWDS components are wired to their behavior after a Turbo navigation
      import components from "uswds/src/js/components"
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
    /* KNOWN ISSUE: only changes to application.postcss.css will trigger an automatic rebuild */
    /* restart your server or run `yarn build:css` when changing other files */
    @import "uswds-settings.scss";
    @import "../../../node_modules/uswds/dist/scss/uswds.scss";
  EOCSS
  gsub_file "app/views/layouts/application.html.erb", "<html>", "<html lang=\"en\">"
  gsub_file "app/views/layouts/application.html.erb", /^\s+<%= yield %>/, <<-EOHTML
    <%= render "application/usa_banner" %>
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
  generate "rspec:install"
  gsub_file "spec/spec_helper.rb", /^=(begin|end)$/, ""

  # Setup the PagesController, locale routes, and home (root) route
  generate :controller, "pages", "home", "--skip-routes", "--no-helper", "--no-assets"

  if @supported_languages.count > 1
    locale_switching = <<~EOM
      around_action :switch_locale

      def switch_locale(&action)
        locale = params[:locale] || I18n.default_locale
        I18n.with_locale(locale, &action)
      end
    EOM
    insert_into_file "app/controllers/application_controller.rb", locale_switching, before: /^end/

    route <<-'EOM'
      scope "(:locale)", locale: /#{I18n.available_locales.join('|')}/ do
        # Your application routes here
        root 'pages#home'
      end
    EOM
  else
    route "root 'pages#home'"
  end
  gsub_file "spec/requests/pages_spec.rb", "/pages/home", "/"
  gsub_file "spec/views/pages/home.html.erb_spec.rb", '  pending "add some examples to (or delete) #{__FILE__}"', <<-EOM
  it "displays the gov banner" do
    render template: "pages/home", layout: "layouts/application"
    expect(rendered).to match "An official website of the United States government"
  end
  EOM

  if run_db_setup
    rails_command "db:create"
    rails_command "db:migrate"
  end
end

# infrastructure & deploy
template "manifest.yml"
copy_file "lib/tasks/cf.rake"
directory "config/deployment"
after_bundle do
  run "cp .gitignore .cfignore" unless skip_git?
end

if @terraform
  directory "terraform", mode: :preserve
  unless skip_git?
    append_to_file ".gitignore", <<~EOM

      # Terraform
      .terraform.lock.hcl
      **/.terraform/*
      secrets.auto.tfvars
      terraform.tfstate
      terraform.tfstate.backup
    EOM
  end
  register_announcement("Terraform", <<~EOM)
    Fill in the cloud.gov organization information in:
      * terraform/bootstrap/main.tf
      * terraform/staging/main.tf
      * terraform/production/main.tf

    Run the bootstrap script and update the appropriate CI/CD environment variables
  EOM
end

if @github_actions
  directory "github", ".github"
  if !@terraform
    remove_file ".github/workflows/terraform-staging.yml"
    remove_file ".github/workflows/terraform-production.yml"
  end
  register_announcement("Github Actions", <<~EOM)
    * Fill in the cloud.gov organization information in .github/workflows/deploy-staging.yml
    * Create environment variable secrets for deploy users
  EOM
end

if @circleci_pipeline
  directory "circleci", ".circleci"
  copy_file "docker-compose.ci.yml"
  template "Dockerfile"
  register_announcement("CircleCI", <<~EOM)
    * Fill in the cloud.gov organization information n the cg-deploy steps
    * Create project environment variables for deploy users
  EOM
else
  remove_file "bin/ci-server-start"
end

if @adrs
  directory "doc"
else
  directory "doc/compliance"
end
register_announcement("Documentation", <<EOM)
* Include a short description of your application in doc/compliance/apps/application.boundary.md
* Remember to keep your Logical Data Model up to date in doc/compliance/apps/data.logical.md
EOM

if @dap
  after_bundle do
    insert_into_file "app/views/layouts/application.html.erb", <<-EODAP, before: /^\s+<\/head>/

    <% if Rails.env.production? %>
      <!-- We participate in the US government's analytics program. See the data at analytics.usa.gov. -->
      <%= javascript_include_tag "https://dap.digitalgov.gov/Universal-Federated-Analytics-Min.js?agency=GSA", async: true, id:"_fed_an_ua_tag" %>
    <% end %>
    EODAP
  end
  register_announcement("Digital Analytics Program", "* Update the DAP agency code in app/views/layouts/application.html.erb")
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
  # x86_64-linux is required to install gems on any linux system such as cloud.gov or CI pipelines
  run "bundle lock --add-platform x86_64-linux"

  # bring generated code into compliance with standard ruby: https://github.com/testdouble/standard
  gsub_file "config/environments/production.rb", "(STDOUT)", "($stdout)"
  gsub_file "config/puma.rb", /\) { (\S+) }/, ', \1)'
  run "bundle exec standardrb --fix"

  unless skip_git?
    git add: '.'
    git commit: "-a -m 'Initial commit'"
  end

  # Post-install announcement
  print_announcements
end
