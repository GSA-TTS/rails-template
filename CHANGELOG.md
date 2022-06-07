## [Unreleased]

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
