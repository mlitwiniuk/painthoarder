require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "confirmed users can sign in by username and email" do
    user = create(:confirmed_user)
    [user.username, user.email].each do |login|
      post user_session_path, params: {user: {login: login, password: "password123"}}
      assert_redirected_to root_path
      get user_paints_path
      assert_response :success
      delete destroy_user_session_path
    end
  end

  test "unconfirmed and locked users cannot sign in" do
    [create(:user), create(:user, :confirmed, :locked)].each do |user|
      post user_session_path, params: {user: {login: user.email, password: "password123"}}
      get user_paints_path
      assert_redirected_to new_user_session_path
    end
  end

  test "confirmation and reconfirmation use mailed tokens" do
    user = create(:user)
    token = user.instance_variable_get(:@raw_confirmation_token)
    assert token.present?
    get user_confirmation_path, params: {confirmation_token: token}
    assert user.reload.confirmed?

    previous_email = user.email
    user.update!(email: "changed@example.com")
    token = user.instance_variable_get(:@raw_confirmation_token)
    assert_equal previous_email, user.reload.email
    assert_equal "changed@example.com", user.unconfirmed_email
    assert token.present?
    get user_confirmation_path, params: {confirmation_token: token}
    assert_equal "changed@example.com", user.reload.email
    assert_nil user.unconfirmed_email
  end

  test "password reset accepts the generated token" do
    user = create(:confirmed_user)
    token = user.send_reset_password_instructions
    put user_password_path, params: {user: {reset_password_token: token,
                                            password: "new-password-123", password_confirmation: "new-password-123"}}
    assert user.reload.valid_password?("new-password-123")
    assert_nil user.reset_password_token
  end
end
