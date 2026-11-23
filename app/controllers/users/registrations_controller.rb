# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    include TurnstileProtection

    protect_with_turnstile only: :create

    private

    def turnstile_failed
      # Runs before configure_permitted_parameters, so permit explicitly (never passwords).
      build_resource(params.fetch(resource_name, {}).permit(:username, :email))
      resource.errors.add(:base, CAPTCHA_FAILED_MESSAGE)
      set_minimum_password_length
      render :new, status: :unprocessable_entity
    end
  end
end
