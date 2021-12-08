gem_group :development, :test do
  gem "rspec-rails"
end

after_bundle do
  rails_command "generate rspec:install"

  unless options[:skip_git]
    git add: '.'
    git commit: "-a -m 'Initial commit'"
  end
end
