# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  include Pagy::Backend

  # allow_browser versions: :modern
  self.responder = ApplicationResponder
  respond_to :html
  layout :set_layout
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::UnknownFormat, with: :unknown_format
  rescue_from Pagy::OverflowError, with: :pagy_overflow

  private

  def record_not_found
    respond_to do |format|
      format.html { render file: Rails.public_path.join("404.html"), layout: false, status: :not_found }
      format.all { head :not_found }
    end
  end

  def unknown_format
    head :not_acceptable
  end

  def pagy_overflow(exception)
    redirect_to url_for(request.query_parameters.merge(page: exception.pagy.last)), status: :moved_permanently
  end

  def set_layout
    if devise_controller?
      "devise"
    else
      "application"
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[username email password password_confirmation])
  end

  def authorize_admin!
    unless current_user&.admin?
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to root_path
    end
  end
end
