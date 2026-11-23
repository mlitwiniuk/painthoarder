# frozen_string_literal: true

module Users
  class PasswordsController < Devise::PasswordsController
    include TurnstileProtection

    protect_with_turnstile only: :create

    private

    def turnstile_failed
      self.resource = resource_class.new(email: params.dig(resource_name, :email))
      resource.errors.add(:base, CAPTCHA_FAILED_MESSAGE)
      render :new, status: :unprocessable_entity
    end
  end
end
