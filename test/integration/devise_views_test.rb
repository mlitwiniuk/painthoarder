require "test_helper"
class DeviseViewsTest < ActionDispatch::IntegrationTest
  test "sign up shows a top alert and inline field errors" do
    create(:confirmed_user, username: "takenname")
    post user_registration_path, params: {user: {username: "takenname", email: "bad", password: "x", password_confirmation: "y"}}
    assert_response :unprocessable_entity
    assert_select "[role=alert]#error_explanation"
    assert_select "input#user_username[aria-invalid=true][aria-describedby=user_username_error]"
    assert_select "#user_username_error", /Username/
  end
  test "failed sign in shows the alert and keeps login and remember me" do
    post user_session_path, params: {user: {login: "nobody", password: "nope"}}
    assert_select "[role=alert]", /Invalid/i
    assert_select "input[name='user[login]']"
    assert_select "input[name='user[remember_me]']"
  end
  test "account settings render" do
    user = create(:confirmed_user)
    sign_in user
    get edit_user_registration_path
    assert_response :success
    assert_select "input[name='user[current_password]']"
  end
  test "landing page renders the catalogue counts" do
    create(:paint)
    get root_path
    assert_response :success
    assert_select "h1", /Your rack/
    assert_select "a[href='#{new_user_registration_path}']", minimum: 1
  end
end
