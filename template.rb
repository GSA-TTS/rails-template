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

def announce_section(section_name, instructions)
  $stdout.puts "\n============= #{section_name} ============= ".yellow
  $stdout.puts instructions
end

@cloudgov_deploy = yes?("Create cloud.gov deployment files? (y/n)")
@github_actions = yes?("Create Github Actions? (y/n)")
@circleci_pipeline = yes?("Create CircleCI config? (y/n)")
@adrs = yes?("Create initial Architecture Decision Records? (y/n)")
@newrelic = yes?("Create FEDRAMP New Relic config files? (y/n)")
@dap = yes?("If this will be a public site, should we include Digital Analytics Program code? (y/n)")
@node_version = ask("What version of NodeJS are you using? (Blank to skip creating .nvmrc)")

# copied from Rails' .ruby-version template implementation
@ruby_version = ENV["RBENV_VERSION"] || ENV["rvm_ruby_string"] || "#{RUBY_ENGINE}-#{RUBY_ENGINE_VERSION}"

if @node_version.present?
  # setup nvmrc
  file ".nvmrc", @node_version
else
  # default to minor version supported by cloud.gov ruby_buildpack
  @node_version = "14.18"
end


## Start of app customizations
template "README.md", force: true


## Get files from Open Source Policy
get "https://raw.githubusercontent.com/18F/open-source-policy/master/CONTRIBUTING.md"
get "https://raw.githubusercontent.com/18F/open-source-policy/master/LICENSE.md"


## setup near-production CI environment
inside "config" do
  copy_file "environments/ci.rb"
  append_to_file "database.yml", <<~EOM

    ci:
      <<: *default
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

  after_bundle do
    copy_file "config/newrelic.yml"

    announce_section("New Relic", <<~EOM)
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
end

gem_group :development, :test do
  gem "rspec-rails", "~> 5.0"
  gem "dotenv-rails", "~> 2.7"
  gem "brakeman", "~> 5.2"
  gem "bundler-audit", "~> 0.9"
  gem "standard", "~> 1.5"
end


copy_file "lib/tasks/scanning.rake"


unless skip_git?
  append_to_file ".gitignore", <<~EOM

    # Ignore local dotenv overrides
    .env*.local

    # Ignore OWASP report file
    zap_report.html

    # Ignore rspec examples status file
    spec/examples.txt
  EOM
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
copy_file "app/views/application/_usa_banner.html.erb"

after_bundle do
  rails_command "generate rspec:install"
  gsub_file "spec/spec_helper.rb", /^=(begin|end)$/, ""

  # setup the PagesController and home (root) route
  generate :controller, "pages", "home", "--skip-routes", "--no-helper", "--no-assets"
  route "root 'pages#home'"
  gsub_file "spec/requests/pages_spec.rb", "/pages/home", "/"
  gsub_file "spec/views/pages/home.html.erb_spec.rb", '  pending "add some examples to (or delete) #{__FILE__}"', <<-EOM
  it "displays the gov banner" do
    render template: "pages/home", layout: "layouts/application"
    expect(rendered).to match "An official website of the United States government"
  end
  EOM

  if yes?("Run db setup steps? (y/n)")
    rails_command "db:create"
    rails_command "db:migrate"
  end
end

if @cloudgov_deploy
  template "manifest.yml"
  directory "config/deployment"
  after_bundle do
    run "cp .gitignore .cfignore" unless skip_git?
  end
end

if @github_actions
  directory "github", ".github"
end

if @circleci_pipeline
  directory "circleci", ".circleci"
  copy_file "docker-compose.ci.yml"
  template "Dockerfile"
else
  remove_file "bin/ci-server-start"
end

if @adrs
  directory "doc/adr"
end

if @dap
  after_bundle do
    insert_into_file "app/views/layouts/application.html.erb", <<-EODAP, before: /^\s+<\/head>/

    <% if Rails.env.production? %>
      <!-- We participate in the US government's analytics program. See the data at analytics.usa.gov. -->
      <%= javascript_include_tag "https://dap.digitalgov.gov/Universal-Federated-Analytics-Min.js?agency=GSA", async: true, id:"_fed_an_ua_tag" %>
    <% end %>
    EODAP
  end
end

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
end
