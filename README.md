18F Rails Template
============================
The 18F Rails template starts or upgrades Rails projects so that they're more secure, follow compliance rules, and are nearly ready to deploy onto cloud.gov. This gem sets up security checks and compliance diagrams, adds the U.S. Web Design System (USWDS), and much much more — [see the full list of features](#features).

This template will create a new Rails 7.0.x project.

[See the `rails-6` branch for Rails 6.1.x](https://github.com/18F/rails-template/tree/rails-6)

## Installation

### For a new Rails project

1. Install the gem:
```
$ gem install rails_template_18f
```

2. Decide whether to install Rails with Hotwire, a framework for client-side interactivity using JavaScript
  - **For entirely server-side rendered applications**, without any Javascript:
    - Use the default configuration (`rails_template_18f <project name> --no-hotwire`)
  - **For applications that need [a bit of client-side interactivity][aBitOfJS]**, but not a full single page application like React or Vue:
    - Use Hotwire (`rails_template_18f <project name> --hotwire`)
  - **For single-page applications** where most of the interaction will take place via JavaScript, and which will use a framework like React or Vue:
    - Use the default configuration (`rails_template_18f <project name> --no-hotwire`)

The `--hotwire` flag means that [Hotwire](https://hotwired.dev/) and [ActionCable](https://guides.rubyonrails.org/action_cable_overview.html) are installed. ActionCable is included to enable the [Turbo Streams](https://turbo.hotwired.dev/handbook/streams) functionality of Hotwire.

Before installing, you may want to consider the other application configuration options in the next section.

[aBitOfJS]: https://engineering.18f.gov/web-architecture/#:~:text=are%20more%20complex-,If%20your%20use%20case%20requires%20a%20bit%20of%20client%2Dside%20interactivity%2C%20use%20the%20above%20options%20with%20a%20bit%20of%20JavaScript.,-You%20might%20use

#### Advanced configuration

There are a variety of options that customize your Rails application.

**Important:** Do not use flags `--skip-bundle` or `--skip-javascript`, or various parts of this template will break.

#### Default configuration

```sh
--skip-active-storage   # Don't include ActiveStorage for document upload
--skip-action-text      # Don't include ActionText libraries for WYSIWYG editing
--skip-action-cable     # Don't include ActionCable websocket implementation
--skip-action-mailbox   # Don't include inbound email
--skip-hotwire          # Don't include Hotwire JS library
--skip-test             # Skip built-in test framework. (We include RSpec)
--javascript=webpack    # Use webpack for JS bundling
--css=postcss           # Use the PostCSS framework for bundling CSS
--template=template.rb  # Add additional configuration from template.rb
--database=postgresql   # Use a PostgreSQL database
```

#### Customizing the installation

| Option | Description |
|--------|-------------|
| `--no-skip-<framework>` | Each of the skipped frameworks listed above (also in `railsrc`) can be overridden on the command line. For example: `--no-skip-active-storage` will include support for `ActiveStorage` document uploads |
| `--javascript=esbuild` | Use [esbuild](https://esbuild.github.io/) instead of [webpack](https://webpack.js.org/) for JavaScript bundling. Note that maintaining IE11 support with esbuild may be tricky. |
| `--no-skip-<FRAMEWORK>` | Each of the skipped frameworks in `railsrc` can be overridden on the command line. For example: `--no-skip-active-storage` will include support for `ActiveStorage` document uploads |

You probably won't want to customize the template — that defeats the purpose of using this gem!

_TODO: Documentation on whether you can override the `css` and `database` options._

### For an existing Rails project

Installing this gem in a new Rails project will _TODO: say how it will help_

Add this line to your application's Gemfile:

```ruby
gem "rails_template_18f", group: :development
```

And then run:

    $ bundle install

For a list of commands this gem can perform, run:

    $ rails generate | grep 18f

_TODO: Add documentation on each option._

### Features

This template does a lot! The template completes the following to-do list to make your application more secure, closer to standards-compliant, and nearly production-ready.

1. Create a better default `README`
1. Copy `CONTRIBUTING.md` and `LICENSE.md` from the [18F Open Source Policy repo](https://github.com/18F/open-source-policy/)
1. Create a "near-production" `ci` Rails environment, used for running a11y and security scans
1. Create a "near-production" `staging` Rails environment, used for cloud.gov staging environment, with a "TEST SITE" warning banner
1. Create a `.nvmrc` file for specifying the NodeJS version in use
1. Set up `pa11y-ci` for a11y scanning
1. Set up `OWASP ZAP` dynamic security scanning
1. Include `secure_headers` gem and configure CSP header to get OWASP passing by default
1. Install and configure [brakeman](https://rubygems.org/gems/brakeman) for static security scanning
1. Install `bundler-audit` and set up `bundle:audit` rake task for Ruby dependency security scans
1. Set up `yarn:audit` rake task for JavaScript dependency security scans
1. Install [Standard Ruby](https://github.com/testdouble/standard) for Ruby linting
1. Install [rspec](https://rubygems.org/gems/rspec-rails) for unit testing
1. Install [dotenv](https://rubygems.org/gems/dotenv-rails) for local configuration
1. Setup Rails credential diffing
1. Create a separate production credentials file.
1. Create a `pre-commit` hook that can be used to automatically run ruby linter & terraform format
1. Setup USWDS via postcss
1. Setup webpack with `.browserslistrc` from USWDS
1. Update `app/views/layouts/application.html.erb` to pass the `pa11y-ci` scan and include the USWDS Banner
1. Create a `PagesController` and root route
1. Create boundary and logical data model compliance diagrams
1. Create `manifest.yml` and variable files for cloud.gov deployment
1. Optionally run the `rake db:create` and `rake db:migrate` setup steps
1. Optionally integrate with https://github.com/GSA-TTS/compliance-template
1. Optionally create GitHub Actions workflows for testing and cloud.gov deploy
1. Optionally create terraform modules supporting staging & production cloud.gov spaces
1. Optionally create CircleCI workflows for testing and cloud.gov deploy
1. Optionally create a New Relic config with FEDRAMP-specific host
1. Optionally configure DAP (Digital Analytics Program)
1. Optionally add base translation files and routes for Spanish, French, and Simplified Chinese (es.yml, fr.yml, and zh.yml)
1. Create [Architecture Decision Records](https://adr.github.io/) for above setup
1. Commit the resulting project with git (unless `--skip-git` is passed)

## Developing this gem

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/18f/rails-template. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/18f/rails-template/blob/main/CODE_OF_CONDUCT.md).

## Code of conduct

Everyone interacting in the 18F Rails Template project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/rahearn/rails-template-18f/blob/main/CODE_OF_CONDUCT.md).
