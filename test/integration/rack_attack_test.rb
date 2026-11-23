require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    @previous_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
  end

  teardown do
    Rack::Attack.reset!
    Rack::Attack.enabled = false
    Rack::Attack.cache.store = @previous_store
  end

  def ip(addr) = {"REMOTE_ADDR" => addr}

  def sign_up(n, env:)
    post user_registration_path, env: env, params: with_turnstile({user: {username: "user#{n}", email: "user#{n}@example.com",
                                                                          password: "password123", password_confirmation: "password123"}})
  end

  test "sign-ups are limited per IP" do
    3.times { |n| sign_up(n, env: ip("203.0.113.1")) }
    assert_not_equal 429, response.status

    sign_up(3, env: ip("203.0.113.1"))
    assert_response :too_many_requests
    assert response.headers["retry-after"].to_i.positive?

    sign_up(4, env: ip("203.0.113.2"))
    assert_not_equal 429, response.status
  end

  test "sign-in bursts are limited per IP, including format-suffixed paths" do
    5.times { post "/users/sign_in.json", params: {user: {login: "x", password: "y"}}, env: ip("203.0.113.3") }
    post user_session_path, params: {user: {login: "x", password: "y"}}, env: ip("203.0.113.3")
    assert_response :too_many_requests
  end

  test "sign-in attempts are limited per login across IPs" do
    10.times { |n| post user_session_path, params: {user: {login: "Victim ", password: "y"}}, env: ip("198.51.100.#{n}") }
    post user_session_path, params: {user: {login: "victim", password: "y"}}, env: ip("198.51.100.99")
    assert_response :too_many_requests
  end

  test "email-sending endpoints are limited per address across IPs" do
    3.times { |n| post user_password_path, params: {user: {email: "a@example.com"}}, env: ip("192.0.2.#{n}") }
    post user_unlock_path, params: {user: {email: "A@example.com"}}, env: ip("192.0.2.50")
    assert_response :too_many_requests
  end

  test "general request limit applies, static assets are exempt" do
    Rack::Attack.throttles["req/ip"].stubs(:limit).returns(2)
    3.times { get "/up", env: ip("192.0.2.200") }
    assert_response :success

    2.times { get root_path, env: ip("192.0.2.200") }
    get root_path, env: ip("192.0.2.200")
    assert_response :too_many_requests
  end
end
