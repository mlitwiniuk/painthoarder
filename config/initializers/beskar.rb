# frozen_string_literal: true

# Beskar: login admission limits, WAF (scanner-path detection), IP bans and a
# security dashboard at /beskar. Docs: https://github.com/humadroid-io/beskar
Beskar.configure do |config|
  # === Dashboard access (Devise admins only) ===
  # Beskar's controller inherits ActionController::Base, so resolve the user
  # through Warden rather than current_user.
  config.authenticate_admin = ->(request) do
    request.env["warden"]&.authenticate(scope: :user)&.admin?
  end
  config.authorize_admin = ->(request, permission) do
    user = request.env["warden"]&.user(scope: :user)
    user&.admin? && user.beskar_permissions.include?(permission.to_s)
  end
  config.audit_actor = ->(request) do
    user = request.env["warden"]&.user(scope: :user)
    "User:#{user.id}" if user&.admin?
  end

  # === Active mode: block requests and ban IPs (false) vs. log only (true) ===
  config.monitor_only = false

  # Trusted IPs/CIDRs that are never auto-blocked.
  config.ip_whitelist = []

  # === WAF ===
  config.waf[:enabled] = true
  # Defaults: score_threshold 150, block_durations [1h, 6h, 24h, 7d],
  # permanent ban at cumulative score 500, exception_detection :suspicious
  # (ordinary 404s from slugs need scanner evidence before they count).

  # === Rate limiting (defaults) ===
  # ip_attempts: 10/hour, account_attempts: 5/15min, both with exponential backoff.
  # Global login budget stays off (shared-quota DoS risk).

  # === Risk-based locking ===
  # Off by default. Users are :lockable, so :devise_lockable can be enabled later;
  # geolocation is :mock (no MaxMind DB), so geographic risk signals are absent.
  # config.risk_based_locking[:enabled] = true
end
