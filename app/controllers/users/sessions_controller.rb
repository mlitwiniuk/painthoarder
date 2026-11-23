# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    include TurnstileProtection

    protect_with_turnstile only: :create

    private

    def turnstile_failed
      self.resource = resource_class.new(login: params.dig(resource_name, :login))
      flash.now[:alert] = CAPTCHA_FAILED_MESSAGE
      render :new, status: :unprocessable_entity
    end
  end
end
