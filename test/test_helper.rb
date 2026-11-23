ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "webmock/minitest"

WebMock.disable_net_connect!(allow_localhost: true)
require "shoulda/matchers"
require_relative "support/shoulda_context_reporter"

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

  TURNSTILE_TOKEN = "test-turnstile-token"

  # Cloudflare accepts any token by default; pass success: false to simulate a failed check.
  setup { stub_turnstile }

  def stub_turnstile(success: true)
    body = success ? {success: true} : {:success => false, "error-codes" => ["invalid-input-response"]}
    stub_request(:post, Turnstile::VERIFY_URL.to_s)
      .to_return(status: 200, body: body.to_json, headers: {"Content-Type" => "application/json"})
  end

  # Form params including the Turnstile widget's hidden field.
  def with_turnstile(params)
    params.merge(Turnstile::RESPONSE_PARAM => TURNSTILE_TOKEN)
  end
end

# Throttling is enabled per test in test/integration/rack_attack_test.rb.
Rack::Attack.enabled = false

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

ActiveSupport.on_load(:action_mailer) do
  Rails.application.reload_routes_unless_loaded
end
