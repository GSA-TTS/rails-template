# frozen_string_literal: true

if ENV["VCAP_SERVICES"].present?
  redis_config = JSON.parse(ENV["VCAP_SERVICES"])["aws-elasticache-redis"]&.first
  return if redis_config.nil?
  redis_url = redis_config["credentials"]["uri"]

  Sidekiq.configure_server do |config|
    config.redis = {url: redis_url, ssl: true}
  end

  Sidekiq.configure_client do |config|
    config.redis = {url: redis_url, ssl: true}
  end
end
