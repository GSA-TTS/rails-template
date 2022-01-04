## Supporting methods
# tell our template to grab all files from the templates directory
def source_paths
  ["#{__dir__}/templates"]
end

def skip_git?
  !!options[:skip_git]
end

def setup_pages_controller
  generate :controller, "pages", "home", "--skip-routes", "--no-helper", "--no-assets"
  route  "root to: 'pages#home'"
  gsub_file "spec/requests/pages_spec.rb", "/pages/home", "/"
  gsub_file "spec/views/pages/home.html.erb_spec.rb", '  pending "add some examples to (or delete) #{__FILE__}"', <<-EOM
  it "displays the gov banner" do
    render template: "pages/home", layout: "layouts/application"
    expect(rendered).to match "An official website of the United States government"
  end
  EOM
end

@cloudgov_deploy = yes?("Create cloud.gov deployment files? (y/n)")
@github_actions = yes?("Create Github Actions? (y/n)")
@adrs = yes?("Create initial Architecture Decision Records? (y/n)")
@node_version = ask("What version of NodeJS are you using? (Blank to skip creating .nvmrc)")

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
after_bundle do
  append_to_file "config/webpacker.yml", <<~EOM

    ci:
      <<: *default
      compile: true
      extract_css: true
    EOM
end


# setup pa11y and owasp scanning
directory "bin", mode: :preserve
copy_file "pa11yci", ".pa11yci"
copy_file "editorconfig", ".editorconfig"
copy_file "zap.conf"
run "yarn add --dev pa11y-ci"

# updates for OWASP scan to pass
gem "secure_headers", "~> 6.3"
initializer "secure_headers.rb", <<~EOM
  SecureHeaders::Configuration.default do |config|
    # CSP settings are handled by Rails
    # see: content_security_policy.rb
    config.csp = SecureHeaders::OPT_OUT
  end
EOM
csp_initializer = "config/initializers/content_security_policy.rb"
# Replace the default commented out block with our locked-down default
gsub_file csp_initializer, /^# Rails.*\|policy\|$.+end$/m, <<~EOM
  Rails.application.config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src :self
    policy.form_action :self
    policy.frame_ancestors :none
    policy.img_src :self, :data
    policy.object_src :none
    policy.script_src :self
    if Rails.env.development?
      # webpack injects styles inline in development mode
      policy.style_src :self, "'unsafe-inline'"
    else
      policy.style_src :self
    end
    # If you are using webpack-dev-server then specify webpack-dev-server host
    policy.connect_src :self, :https, "http://localhost:3035", "ws://localhost:3035" if Rails.env.development?
  end
EOM
# uncommenting the nonce generation lines is needed for Rails' UJS to work
uncomment_lines csp_initializer, "content_security_policy_nonce"


gem_group :development, :test do
  gem "rspec-rails", "~> 5.0"
  gem "dotenv-rails", "~> 2.7"
  gem "brakeman", "~> 5.1"
  gem "bundler-audit", "~> 0.9"
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
run "yarn add uswds"
run "yarn add resolve-url-loader"
append_to_file "app/javascript/packs/application.js", <<~EOJS

  import 'css/application.scss'
  import 'uswds/dist/img/icon-dot-gov.svg'
  import 'uswds/dist/img/us_flag_small.png'
  import 'uswds/dist/img/icon-https.svg'

  document.addEventListener("DOMContentLoaded", () => {
    require('uswds')
  })
EOJS
directory "app/javascript/css"
after_bundle do
  insert_into_file "config/webpack/environment.js", <<~EOJS, before: "module.exports = environment"
    // Place resolve-url-loader into webpack loaders config
    // source: https://github.com/rails/webpacker/issues/2155#issuecomment-829741240
    environment.loaders.get('sass').use.splice(-1, 0, {
      loader: 'resolve-url-loader'
    })

  EOJS
end
template "app/views/layouts/application.html.erb", force: true
copy_file "app/views/application/_usa_banner.html.erb"


after_bundle do
  rails_command "generate rspec:install"
  setup_pages_controller
  gsub_file "spec/spec_helper.rb", /^=(begin|end)$/, ""

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

if @adrs
  directory "doc/adr"
end

# ensure this is the very last step
after_bundle do
  # x86_64-linux is required to install gems on any linux system such as cloud.gov or CI pipelines
  run "bundle lock --add-platform x86_64-linux"
  unless skip_git?
    git add: '.'
    git commit: "-a -m 'Initial commit'"
  end
end
