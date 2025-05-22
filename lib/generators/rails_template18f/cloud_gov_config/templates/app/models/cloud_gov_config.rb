# frozen_string_literal: true

class CloudGovConfig
  attr_reader :vcap_services

  def initialize(env = ENV["VCAP_SERVICES"])
    @vcap_services = env.blank? ? {} : JSON.parse(env).with_indifferent_access
  end

  def dig(*path)
    first, *rest = path
    vcap_services[first]&.first&.dig(*rest)
  end
end
