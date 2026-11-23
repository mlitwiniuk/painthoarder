require "test_helper"

class TurnstileIntegrationTest < ActionDispatch::IntegrationTest
  MESSAGE = TurnstileProtection::CAPTCHA_FAILED_MESSAGE

  test "the widget is rendered on every protected form" do
    [new_user_session_path, new_user_registration_path, new_user_password_path,
      new_user_confirmation_path, new_user_unlock_path].each do |path|
      get path
      assert_select "form [data-controller=turnstile][data-turnstile-site-key-value='#{Turnstile.site_key}']", 1, path
    end
  end

  test "sign in without a token is rejected before the password is checked" do
    user = create(:confirmed_user)
    post user_session_path, params: {user: {login: user.username, password: "wrong"}}
    assert_response :unprocessable_entity
    assert_select "[role=alert]", /#{MESSAGE}/o
    assert_select "input[name='user[login]'][value='#{user.username}']"
    assert_equal 0, user.reload.failed_attempts
    assert_not_requested :post, Turnstile::VERIFY_URL.to_s
  end

  test "sign in with a rejected token does not log the user in" do
    stub_turnstile(success: false)
    user = create(:confirmed_user)
    post user_session_path, params: with_turnstile({user: {login: user.username, password: "password123"}})
    assert_response :unprocessable_entity
    get user_paints_path
    assert_redirected_to new_user_session_path
  end

  test "sign up with a rejected token creates no user and keeps the form" do
    stub_turnstile(success: false)
    assert_no_difference "User.count" do
      post user_registration_path, params: with_turnstile({user: {username: "newbie", email: "newbie@example.com",
                                                                  password: "password123", password_confirmation: "password123"}})
    end
    assert_response :unprocessable_entity
    assert_select "#error_explanation", /#{MESSAGE}/o
    assert_select "input[name='user[username]'][value=newbie]"
    assert_select "input[name='user[password]']:not([value])"
  end

  test "sign up with a valid token creates the user" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: with_turnstile({user: {username: "newbie", email: "newbie@example.com",
                                                                  password: "password123", password_confirmation: "password123"}})
    end
  end

  test "email-sending forms send nothing without a valid token" do
    user = create(:confirmed_user, :locked)
    stub_turnstile(success: false)
    assert_no_enqueued_emails do
      [user_password_path, user_confirmation_path, user_unlock_path].each do |path|
        post path, params: with_turnstile({user: {email: user.email}})
        assert_response :unprocessable_entity
        assert_select "#error_explanation", /#{MESSAGE}/o
      end
    end
  end

  test "password reset with a valid token sends the email" do
    user = create(:confirmed_user)
    assert_emails 1 do
      post user_password_path, params: with_turnstile({user: {email: user.email}})
    end
  end
end
