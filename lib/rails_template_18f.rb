# frozen_string_literal: true

require_relative "rails_template_18f/version"

module RailsTemplate18f
  class Error < StandardError; end
  class Railtie < ::Rails::Railtie; end
end
