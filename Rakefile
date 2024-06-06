# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

task default: %i[spec standard]

task :release do
  # adding a custom release task because I can't get the default `rake release` to play nicely with my
  # passkey login to rubygems.org on GFE, so I need to use the `gem push --otp` version.
  # set the environment variable gem_push=false to enable this block
  gemhelper = Bundler::GemHelper.instance
  unless gemhelper.send :gem_push?
    gemspec = gemhelper.gemspec
    Bundler.ui.warn "Next step: publish the #{gemspec.name} gem with:"
    Bundler.ui.warn "gem push pkg/#{gemspec.name}-#{gemspec.version}.gem --otp OTP"
  end
end
