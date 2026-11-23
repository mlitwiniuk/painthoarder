require "test_helper"

class BeskarTest < ActionDispatch::IntegrationTest
  test "security dashboard is restricted to admins" do
    get "/beskar"
    assert_response :not_found

    sign_in create(:confirmed_user)
    get "/beskar"
    assert_response :not_found

    sign_in create(:confirmed_user, is_admin: true)
    get "/beskar"
    assert_response :success
  end

  test "admins hold every dashboard permission, other users none" do
    assert_equal %w[read manage_bans export read_audit], build(:user, is_admin: true).beskar_permissions
    assert_empty build(:user).beskar_permissions
  end

  test "WAF bans an IP that keeps probing scanner paths" do
    headers = {"REMOTE_ADDR" => "203.0.113.7"}
    10.times do
      get "/.env", env: headers
      break if response.status == 403
    end
    assert_equal 403, response.status
    assert Beskar::BannedIp.banned?("203.0.113.7")

    # Banned IP is blocked everywhere, other clients are not.
    get root_path, env: headers
    assert_equal 403, response.status
    get root_path, env: {"REMOTE_ADDR" => "203.0.113.8"}
    assert_response :success
  end

  test "repeated failed logins from one IP are rate limited" do
    user = create(:confirmed_user)
    headers = {"REMOTE_ADDR" => "198.51.100.9"}
    statuses = 12.times.map do |i|
      post user_session_path, params: with_turnstile({user: {login: "nobody#{i}", password: "wrong"}}), env: headers
      response.status
    end
    assert_includes statuses, 429

    # Account itself is untouched; a different IP can still sign in.
    post user_session_path, params: with_turnstile({user: {login: user.username, password: "password123"}}),
      env: {"REMOTE_ADDR" => "198.51.100.10"}
    assert_redirected_to root_path
  end
end
