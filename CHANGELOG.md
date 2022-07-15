## [Unreleased]

- add a doc/compliance/TODO.md file with tasks that can sometimes be useful on the ATO journey.
- generalize create_space_deployer.sh to create_service_account.sh to make it easier to create SpaceAuditor users

## [0.8.0] - 2022-07-14

- use rails-erd gem for auto-updating logical data models
- use cleaner multi-line strings for GitHub Actions deploy steps
- generate an SBOM for ruby dependencies in either Github Actions or CircleCI using cyclonedx-ruby

## [0.7.2] - 2022-07-07

- update default node version in github actions to 16.15
- update OSCAL message format to include the app_name as an OSCAL component once assembled

## [0.7.1] - 2022-07-05

- fix issue with initial git commit when no OSCAL docs were updated during initial app creation
- add extra content to project README about working with submodules

## [0.7.0] - 2022-07-05

- OSCAL generator to integrate with https://github.com/GSA-TTS/compliance-template

## [0.6.0] - 2022-06-07

- include USWDS 3.0 for new apps
- use postcss-minify instead of the sass gem for CSS minimization

## [0.5.3] - 2022-06-06

- check that server started properly before running anything in `bin/with-server`
- add helper script for setting cloud.gov egress rules

## [0.5.2] - 2022-03-24

- add extra branch test coverage to CloudGovConfig
- replace forked version of @csstools/postcss-sass with released version
- upgrade i18n-tasks gem to 1.0

## [0.5.1] - 2022-03-17

- fix interaction between foreman and dotenv by disabling foreman's env loading

## [0.5.0] - 2022-03-04

- use Brewfile for installing homebrew-based dependencies
- move test site banner to the _usa_banner.html.erb partial
- use dockerize within bin/with-server to wait for rails to start

## [0.4.1] - 2022-02-25

- update gem dependencies
- fix issues when included gem hadn't been previously installed

## [0.4.0] - 2022-02-24

- helper script to run rails app:update
- cloud.gov configuration helper generator
- activestorage/clamav generator
- activejob/sidekiq generator
- i18n-js generator

## [0.3.0] - 2022-02-17

- i18n generator
- helper script to run rails new without cloning repo

## [0.2.0] - 2022-02-16

- terraform generator
- DAP generator
- Newrelic generator

## [0.1.0] - 2022-02-14

- Initial release
- circleci and github_actions generators for adding CI/CD pipeline to your project
