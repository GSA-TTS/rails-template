## [Unreleased]

- add extra branch test coverage to CloudGovConfig

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
