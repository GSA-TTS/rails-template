# frozen_string_literal: true

require_relative "rails_template18f/version"
require_relative "rails_template18f/generators"

module RailsTemplate18f
  class Error < StandardError; end

  class Railtie < ::Rails::Railtie; end
end
