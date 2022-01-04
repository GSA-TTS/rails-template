18F-Flavored Rails 7 Project
============================

This template will create a new Rails 7.0.x project.

See the `main` branch for Rails 6.1.x

## Usage

1. Clone this repository to your computer
1. Change directory into the clone
1. `rails new <<PATH_TO_PROJECT>> --rc=railsrc` The path should not be a subdirectory of this repository.

### Available Options

The following options can be added after `--rc=railsrc` to change how the template behaves.

**Important:** You must not pass `--skip-bundle` or `--skip-javascript` to `rails new` or various aspects of the template will be broken

#### `--javascript=esbuild`

Use [esbuild](https://esbuild.github.io/) instead of [webpack](https://webpack.js.org/) for javascript bundling. Note that
maintaining IE11 support with esbuild may be tricky.

#### `--no-skip-FRAMEWORK`

Each of the skipped frameworks in `railsrc` can be overridden on the command line. For example: `--no-skip-active-storage` will include support for `ActiveStorage` document uploads

### What `railsrc` does

```
--skip-active-storage   # don't include ActiveStorage for document upload
--skip-action-text      # don't include ActionText libraries for WYSIWYG editing
--skip-action-cable     # don't include ActionCable websocket implementation
--skip-action-mailbox   # don't include inbound email
--skip-hotwire          # don't include Hotwire JS library
--skip-test             # Skip built in test framework. (RSpec included via template.rb)
--javascript=webpack    # Use webpack for JS bundling
--css=postcss           # Use the postcss CSS bundling framework
--template=template.rb  # add additional configuration from template.rb
--database=postgresql   # default to PostgreSQL
```

You may want to edit that file if you do need some of those frameworks for your project. They can also
be added after your project needs them.

### What `template.rb` does

1. Create a better default README
1. Copy CONTRIBUTING.md and LICENSE.md from the 18F Open Source Policy repo
1. Create a "near-production" `ci` Rails environment, used for running a11y and security scans
1. Optionally create a `.nvmrc` file for specifying the NodeJS version in use
1. Set up `pa11y-ci` for a11y scanning
1. Set up `OWASP ZAP` dynamic security scanning
1. Include `secure_headers` gem and configure CSP header to get OWASP passing by default
1. Install and configure [brakeman](https://rubygems.org/gems/brakeman) for static security scanning
1. Install `bundler-audit` and set up `bundle:audit` rake task for Ruby dependency security scans
1. Set up `yarn:audit` rake task for JavaScript dependency security scans
1. Install [Standard Ruby](https://github.com/testdouble/standard) for Ruby linting
1. Install [rspec](https://rubygems.org/gems/rspec-rails) for unit testing
1. Install [dotenv](https://rubygems.org/gems/dotenv-rails) for local configuration
1. Setup USWDS via postcss
1. Setup webpack with `.browserslistrc` from USWDS
1. Update `app/views/layouts/application.html.erb` to pass the `pa11y-ci` scan and include the USWDS Banner
1. Create a `PagesController` and root route
1. Optionally run the `rake db:create` and `rake db:migrate` setup steps
1. Optionally create `manifest.yml` and variable files for cloud.gov deployment
1. Optionally create Github Actions workflows
1. Optionally create [Architecture Decision Records](https://adr.github.io/) for above setup
1. Commit the resulting project with git (unless `--skip-git` is passed)
