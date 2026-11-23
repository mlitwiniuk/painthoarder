# frozen_string_literal: true

# Sign-in/sign-up are protected by Cloudflare Turnstile (see app/services/turnstile.rb),
# which fails closed. Refuse to boot in production without keys rather than
# rejecting every login. Skipped for the asset-precompile build step.
Rails.application.config.after_initialize do
  if Rails.env.production? && ENV["SECRET_KEY_BASE_DUMMY"].blank? && !Turnstile.configured?
    raise "Cloudflare Turnstile keys missing: set turnstile.site_key/secret_key in credentials " \
      "or TURNSTILE_SITE_KEY/TURNSTILE_SECRET_KEY"
  end
end
