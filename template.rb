def source_paths
  ["#{__dir__}/templates"]
end

template "README.md", force: true

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
