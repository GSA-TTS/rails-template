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

template "README.md", force: true


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


# setup nvmrc
node_version = ask("What version of NodeJS are you using? (Blank to skip creating .nvmrc)")
file ".nvmrc", node_version unless node_version.blank?


# setup pa11y and owasp scanning
directory "bin", mode: :preserve
copy_file "pa11yci", ".pa11yci"
copy_file "editorconfig", ".editorconfig"
copy_file "zap.conf"
run "yarn add --dev pa11y-ci"


gem_group :development, :test do
  gem "rspec-rails", "~> 5.0"
  gem "dotenv-rails", "~> 2.7"
  gem "brakeman", "~> 5.1"
end


copy_file "lib/tasks/scanning.rake"


unless skip_git?
  append_to_file ".gitignore", <<~EOM

    # Ignore local configuration overrides
    .env*.local
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

  unless skip_git?
    git add: '.'
    git commit: "-a -m 'Initial commit'"
  end
end
