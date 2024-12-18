18F Rails Template
============================
The 18F Rails template starts or upgrades Rails projects so that they're more secure, follow compliance rules, and are nearly ready to deploy onto cloud.gov. This gem sets up security checks and compliance diagrams, adds the U.S. Web Design System (USWDS), and much much more — [see the full list of features](#features).

This template will create a new Rails 8.0.x project.

[See the `rails-7.2` branch for Rails 7.2.x](https://github.com/gsa-tts/rails-template/tree/rails-7.2)

## Usage

### For a new Rails project

#### Install the gem:
```
$ gem install rails_template_18f
```

#### Decide whether to install Rails with Hotwire

[Hotwire](hotwire) is a framework for client-side interactivity using JavaScript that stops short of a full Single Page Application (SPA) framework like React or Vue.

It is a good choice if you need [a bit of client-side interactivity][aBitOfJS]. Do not use Hotwire if you either will have almost no Javascript at all, or if you are going to use a full SPA.

#### Review the defaults and decide if you want to override any of them

<details><summary>Default configuration</summary>

```sh
--skip-active-storage   # Don't include ActiveStorage for document upload
--skip-action-text      # Don't include ActionText libraries for WYSIWYG editing
--skip-action-cable     # Don't include ActionCable websocket implementation
--skip-action-mailbox   # Don't include inbound email
--skip-hotwire          # Don't include Hotwire JS library
--skip-docker           # Don't include Dockerfile meant for production use
--skip-test             # Skip built-in test framework. (We include RSpec)
--javascript=webpack    # Use webpack for JS bundling
--css=postcss           # Use the PostCSS framework for bundling CSS
--template=template.rb  # Add additional configuration from template.rb
--database=postgresql   # Use a PostgreSQL database
--skip-rubocop          # Skip rubocop integration in favor of Standard Ruby
--skip-ci               # Skip github actions in favor of our CI generators
--skip-kamal            # Skip kamal deployment system
--skip-thruster         # Skip thruster reverse proxy
--skip-solid            # Skip solid cache,queue,websocket additions
```

If you are using Hotwire, then `--skip-hotwire` and `--skip-action-cable` are automatically removed from this list, as they are required for the Hotwire functionality.
</details>
<br />

Add the following options at the end of your `rails_template_18f new` command to overwrite any of those defaults.

| Option | Description |
|--------|-------------|
| `--no-skip-<framework>` | Each of the skipped frameworks listed above (also in `railsrc`) can be overridden on the command line. For example: `--no-skip-active-storage` will include support for `ActiveStorage` document uploads |
| `--javascript=esbuild` | Use [esbuild](https://esbuild.github.io/) instead of [webpack](https://webpack.js.org/) for JavaScript bundling. Note that maintaining IE11 support with esbuild may be tricky. |

_TODO: Documentation on whether you can override the `css` and `database` options._

**Important:** Do not use flags `--skip-bundle` or `--skip-javascript`, or various parts of this template will break.

#### Create your application

<details><summary>If you are using Hotwire, run:</summary>

```
$ rails_template_18f new <project name> --hotwire ADDITIONAL_CONFIG_OPTIONS
```
</details>

<details><summary>If you are not using Hotwire, run:</summary>

```
$ rails_template_18f new <project name> ADDITIONAL_CONFIG_OPTIONS
```
</details>

#### Answer the setup questions that the template asks

The template asks questions to ensure your new application is set up for your use case.

<details><summary>Set up docker-trestle integration for Compliance-as-Code?</summary>

Answer `y` to integrate with [docker-trestle](https://github.com/gsa-tts/docker-trestle) for creating compliance documents in markdown and [OSCAL](https://pages.nist.gov/OSCAL/).

Follow up questions if you answer `y`:
* "Set up compliance documents as a git submodule?" Answer `y` if you want compliance documents to be stored in a separate git repository and linked to your app as a submodule. Answer `n` to have documents checked directly into your code repo.
  * If you answer `y`, you'll need to provide the address of the compliance repository.
* "Run compliance checks with auditree?" Answer `y` if you want to integrate with [auditree](https://github.com/gsa-tts/auditree-devtools) for automated compliance checks.
</details>

<details><summary>Create terraform files for cloud.gov services?</summary>

Answer `y` to run the `terraform` generator. This includes a `/terraform` folder defining services and infrastructure within cloud.gov as well as support for deploying that infrastructure in your chosen CI/CD pipeline.
</details>

<details><summary>Cloud.gov organization and space names</summary>

Provide your cloud.gov organization and space names for use in terraform and deploy scripts.
</details>

<details><summary>Create GitHub Actions?</summary>

Answer `y` to create Github Actions workflows for running tests, scans, and deploys. Also configures Dependabot.
</details>

<details><summary>Create CircleCI config?</summary>

Answer `y` to create a CircleCI workflow for running tests, scans, and deploys.
</details>

<details><summary>Create FEDRAMP New Relic config files?</summary>

Answer `y` to create a default New Relic config that can speak to the Government-flavored New Relic instance, including updating Content Security Policy headers so that browser metrics can be collected.
</details>

<details><summary>If this will be a public site, should we include Digital Analytics Program code?</summary>

Answer `y` to set up an integration with DAP.
</details>

<details><summary>Supported locales</summary>

Answer `y` for any languages that should be supported out of the box. Translations are supplied for the usa-banner. You will still be responsible for translating any application content.
</details>

<details><summary>Run db setup steps?</summary>

Answer `y` to run `rake db:create && rake db:migrate` as part of the app setup. PostgreSQL must be running or this will fail.
</details>

### For an existing Rails project

Installing this gem in a new Rails project will _TODO: say how it will help_

Add this line to your application's Gemfile:

```ruby
gem "rails_template_18f", group: :development
```

And then run:

```sh
$ bundle install
```

For a list of commands this gem can perform, run:

```sh
$ bin/rails generate | grep 18f
```

Run `bin/rails generate rails_template_18f:GENERATOR --help` for information on each generator.

### Features

<details><summary>This template does a lot! The template completes the following to-do list to make your application more secure, closer to standards-compliant, and nearly production-ready.</summary>

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
1. Optionally integrate with https://github.com/GSA-TTS/docker-trestle
1. Optionally integrate with https://github.com/GSA-TTS/auditree-devtools
1. Optionally create GitHub Actions workflows for testing and cloud.gov deploy
1. Optionally create terraform modules supporting staging & production cloud.gov spaces
1. Optionally create CircleCI workflows for testing and cloud.gov deploy
1. Optionally create a New Relic config with FEDRAMP-specific host
1. Optionally configure DAP (Digital Analytics Program)
1. Optionally add base translation files and routes for Spanish, French, and Simplified Chinese (es.yml, fr.yml, and zh.yml)
1. Create [Architecture Decision Records](https://adr.github.io/) for above setup
1. Commit the resulting project with git (unless `--skip-git` is passed)
</details>

## Developing this gem

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gsa-tts/rails-template. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/gsa-tts/rails-template/blob/main/CODE_OF_CONDUCT.md).

## Code of conduct

Everyone interacting in the 18F Rails Template project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/gsa-tts/rails-template/blob/main/CODE_OF_CONDUCT.md).

[hotwire]: https://hotwired.dev/
[aBitOfJS]: https://guides.18f.gov/engineering/tools/web-architecture/#if-your-use-case-requires-a-bit-of-client-side-interactivity-use-the-above-options-with-a-bit-of-javascript
