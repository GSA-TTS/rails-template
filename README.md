18F-Flavored Rails Project
==========================

## Usage

`rails new <<PATH_TO_PROJECT>> --rc=railsrc`

**Important:** You must not pass `--skip-bundle` or `--skip-webpack-install` to `rails new` or various aspects of the template will be broken

### What railsrc does

```
--skip-active-storage   # don't include ActiveStorage for document upload
--skip-action-text      # don't include ActionText libraries for WYSIWYG editing
--skip-action-cable     # don't include ActionCable websocket implementation
--skip-action-mailbox   # don't include inbound email
--skip-turbolinks       # don't include Turbolinks JS library
--skip-spring           # don't include Spring application preloader
--skip-test             # Skip built in test framework. (RSpec included via template.rb)
--template=template.rb  # add additional configuration from template.rb
--database=postgresql   # default to PostgreSQL
```

You may want to edit that file if you do need some of those frameworks

### What template.rb does

1. Create a better default README
1. Create a "near-production" `ci` Rails environment, used for running a11y and security scans
1. Optionally create a `.nvmrc` file
1. Set up `pa11y-ci` for a11y scanning
1. Set up `OWASP ZAP` dynamic security scanning
1. Include `secure_headers` gem and configure CSP header to get OWASP passing by default
1. Install and configure [brakeman](https://rubygems.org/gems/brakeman) for static security scanning
1. Install [rspec](https://rubygems.org/gems/rspec-rails) for unit testing
1. Install [dotenv](https://rubygems.org/gems/dotenv-rails) for local configuration
1. Setup USWDS via webpacker
1. Install new `app/views/layouts/application.html.erb` that passes the `pa11y-ci` scan and includes the USWDS Banner
1. Create a `PagesController` and root route
1. Optionally run the `rake db:create` and `rake db:migrate` setup steps
1. Optionally create `manifest.yml` and variable files for cloud.gov deployment
1. Optionally create Github Actions workflows
1. Optionally create [Architecture Decision Records](https://adr.github.io/) for above setup
1. Commit the resulting project with git (unless `--skip-git` is passed)
