# frozen_string_literal: true

# Request throttling. Complements Beskar (WAF, IP bans, per-account login
# admission) and Devise :lockable. Counters live in Rails.cache (Solid Cache in
# production, so they are shared across Puma workers).
#
# Limits are per client IP as resolved by ActionDispatch::RemoteIp (the same
# address Beskar uses), plus per-identity limits for login/email endpoints.
class Rack::Attack
  MINUTE = 60
  HOUR = 60 * MINUTE
  DAY = 24 * HOUR

  EMAIL_ENDPOINTS = %w[/users/password /users/confirmation /users/unlock].freeze
  EXPENSIVE_ENDPOINTS = %w[/user_paints/bulk_search_from_photo /videos].freeze # paid LLM calls
  STATIC_PREFIXES = %w[/assets/ /rails/active_storage/ /sitemaps/ /icon /service-worker /favicon /robots.txt /up].freeze

  class Request < ::Rack::Request
    def remote_ip
      @remote_ip ||= (env["action_dispatch.remote_ip"] || ip).to_s
    end

    # Path without trailing slash or format suffix (/users/sign_in.json -> /users/sign_in).
    def normalized_path
      @normalized_path ||= path.delete_suffix("/").sub(/\.\w+\z/, "")
    end

    def post_to?(paths)
      post? && Array(paths).include?(normalized_path)
    end

    def static?
      STATIC_PREFIXES.any? { |prefix| path.start_with?(prefix) }
    end

    def user_param(key)
      value = params.dig("user", key)
      value.strip.downcase.presence if value.is_a?(String)
    rescue => _e # malformed body; the IP throttles still apply
      nil
    end
  end

  # --- General ---------------------------------------------------------------
  throttle("req/ip", limit: 600, period: 5 * MINUTE) do |req|
    req.remote_ip unless req.static?
  end

  # --- Sign in (Beskar also limits failed attempts per IP and per account) ----
  throttle("sign_in/ip/burst", limit: 5, period: 20) do |req|
    req.remote_ip if req.post_to?("/users/sign_in")
  end
  throttle("sign_in/ip", limit: 20, period: HOUR) do |req|
    req.remote_ip if req.post_to?("/users/sign_in")
  end
  throttle("sign_in/login", limit: 10, period: HOUR) do |req|
    req.user_param("login") if req.post_to?("/users/sign_in")
  end

  # --- Sign up ---------------------------------------------------------------
  throttle("sign_up/ip", limit: 3, period: HOUR) do |req|
    req.remote_ip if req.post_to?("/users")
  end
  throttle("sign_up/ip/day", limit: 5, period: DAY) do |req|
    req.remote_ip if req.post_to?("/users")
  end

  # --- Endpoints that send email (reset, confirmation, unlock) ----------------
  throttle("email/ip", limit: 5, period: HOUR) do |req|
    req.remote_ip if req.post_to?(EMAIL_ENDPOINTS)
  end
  throttle("email/address", limit: 3, period: HOUR) do |req|
    req.user_param("email") if req.post_to?(EMAIL_ENDPOINTS)
  end

  # --- Costly endpoints (LLM-backed) -----------------------------------------
  throttle("expensive/ip", limit: 30, period: HOUR) do |req|
    req.remote_ip if req.post_to?(EXPENSIVE_ENDPOINTS)
  end

  self.throttled_responder = lambda do |req|
    match = req.env["rack.attack.match_data"] || {}
    period = match[:period].to_i
    retry_after = period.positive? ? period - (match[:epoch_time].to_i % period) : 60
    [429, {"content-type" => "text/plain", "retry-after" => retry_after.to_s},
      ["Too many requests. Please try again in #{retry_after} seconds.\n"]]
  end
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
  req = payload[:request]
  Rails.logger.warn("[Rack::Attack] throttled #{req.env["rack.attack.matched"]} ip=#{req.remote_ip} path=#{req.path}")
end
