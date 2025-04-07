ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "shoulda/matchers"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Add more helper methods to be used by all tests here...
    #

    include FactoryBot::Syntax::Methods
  end
end

# Configure Devise for testing
class ActionController::TestCase
  include Devise::Test::ControllerHelpers
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end

# Monkey patch for Devise testing in unit tests
module DeviseTestHelpers
  def setup_devise_mapping
    @request ||= ActionController::TestRequest.create(Rails.application)
    @controller ||= ApplicationController.new
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end
end

# Enable Devise mappings for all ActiveSupport tests
class ActiveSupport::TestCase
  include DeviseTestHelpers

  setup :setup_devise_mapping
end

# Disable actual mail delivery in tests
ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = false

# Override Devise confirmable and prevent callbacks
module DisableDeviseEmailsAndConfirmation
  def send_confirmation_instructions
    # Do nothing during tests
  end

  def send_on_create_confirmation_instructions
    # Do nothing during tests
  end

  def send_reset_password_instructions
    # Do nothing during tests
  end

  def send_unlock_instructions
    # Do nothing during tests
  end
end

class User < ApplicationRecord
  prepend DisableDeviseEmailsAndConfirmation
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

ActiveSupport.on_load(:action_mailer) do
  Rails.application.reload_routes_unless_loaded
end
