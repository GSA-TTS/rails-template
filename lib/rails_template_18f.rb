# frozen_string_literal: true

require_relative "rails_template18f/version"

module RailsTemplate18f
  extend ActiveSupport::Autoload

  autoload :TerraformOptions

  class Error < StandardError; end

  class Railtie < ::Rails::Railtie; end
end
