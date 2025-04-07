require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  include Warden::Test::Helpers

  # Make sure test helpers are properly torn down after each test
  teardown do
    Warden.test_reset!
  end
end
