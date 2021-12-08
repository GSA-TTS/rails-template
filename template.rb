# tell our template to grab all files from the templates directory
def source_paths
  ["#{__dir__}/templates"]
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
  if webpack_install? && bundle_install?
    append_to_file "config/webpacker.yml", <<~EOM

      ci:
        <<: *default
        compile: true
        extract_css: true
      EOM
  end
end


# setup pa11y and owasp scanning
directory "bin", mode: :preserve
copy_file "pa11yci", ".pa11yci"
copy_file "editorconfig", ".editorconfig"
copy_file "zap.conf"
run "yarn add --dev pa11y-ci"


gem_group :development, :test do
  gem "rspec-rails", "~> 5.0"
  gem "dotenv-rails", "~> 2.7"
end


unless options[:skip_git]
  append_to_file ".gitignore", <<~EOM

    # Ignore local configuration overrides
    .env*.local
  EOM
end

after_bundle do
  rails_command "generate rspec:install"

  unless options[:skip_git]
    git add: '.'
    git commit: "-a -m 'Initial commit'"
  end
end
