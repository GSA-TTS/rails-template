# frozen_string_literal: true

class CloudGovConfig
  ENV_VARIABLE = "VCAP_SERVICES"

  def self.dig(*path)
    return nil if ENV[ENV_VARIABLE].blank?
    first, *rest = path
    vcap_services[first]&.first&.dig(*rest)
  end

  def self.vcap_services
    if Rails.env.test?
      parse_env
    else
      @vcap_services ||= parse_env
    end
  end

  private_class_method def self.parse_env
    JSON.parse(ENV[ENV_VARIABLE]).with_indifferent_access
  end
end
