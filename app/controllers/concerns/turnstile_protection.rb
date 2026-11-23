# frozen_string_literal: true

# Requires a valid Cloudflare Turnstile token on the given Devise actions.
#
# Must be added with prepend_before_action: Devise's SessionsController runs the
# password strategy inside its own (prepended) before_actions, so a plain
# before_action would check the captcha only after the password was verified.
module TurnstileProtection
  extend ActiveSupport::Concern

  CAPTCHA_FAILED_MESSAGE = "Please complete the security check and try again."

  class_methods do
    def protect_with_turnstile(**options)
      prepend_before_action :verify_turnstile!, **options
    end
  end

  private

  def verify_turnstile!
    return if Turnstile.verify(params[Turnstile::RESPONSE_PARAM], remote_ip: request.remote_ip)

    turnstile_failed
  end

  # Each controller re-renders its form with the error and the submitted values.
  def turnstile_failed
    raise NotImplementedError
  end
end
