## [Unreleased]

- Default new apps to Rails 8, including support for thruster proxy
- Massive overhaul of the Terraform generator
  - Creates and configures spaces for app and egress proxy
  - Moves from module-per-environment to a single module with per-env variable files
  - Ability for a one-script deployment from nothing, enabling easy developer sandboxes and review apps
- Add asset cacheing to Github Actions & CircleCI deploy workflows to enable serving in-flight asset requests without error

## [1.3.0] - 2024-12-18

- Set up app space via terraform, with proper restricted egress security group
- Create rails_template18f:public_egress generator for integrating with cg-egress-proxy
- [Use exec when starting rails server](https://docs.cloudfoundry.org/devguide/deploy-apps/manifest-attributes.html#start-commands:~:text=To%20resolve%20this,process.%20For%20example%3A)
- Upgrade the i18n-js integration to 4.x

## [1.2.0] - 2024-09-20

- new applications are now on Rails 7.2.x
- configure dependabot in Github Actions generator
- fix bin/trestle and bin/auditree so that command line flags are properly passed into the docker containers
- updates to trestle and auditree github actions

## [1.1.0] - 2024-08-20

- add an auditree generator for integration with auditree-devtools and github actions to run it
- remove the obsolete entry to include nodejs_buildpack in cloud.gov manifest.yml

## [1.0.0] - 2024-06-27

- new applications are now on Rails 7.1.x
- implement USWDS language selector component when translation files are included
- cleans up github actions and circleci generators to address bitrot
- utilize docker-trestle project for OSCAL integration / compliance as code

## [0.8.2] - 2024-06-06

- Replace deprecated github action for cloud.gov deploys with cg-supported one
- Update terraform modules use for the actual module api - and specify the module version in use

## [0.8.1] - 2024-06-04

- fix error when compliance-template fork question is left blank
- fix deprecated and then removed use of `npm set-scripts`
- add a doc/compliance/TODO.md file with tasks that can sometimes be useful on the ATO journey.
- generalize create_space_deployer.sh to create_service_account.sh to make it easier to create SpaceAuditor users
- move support scripts set_space_egress.sh, create_service_account.sh, and destroy_service_account.sh out of terraform generator

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
