require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "welcome" do
    user = create(:confirmed_user)
    mail = UserMailer.with(user:).welcome
    assert_equal "Welcome to PaintHoarder", mail.subject
    assert_equal [user.email], mail.to
    assert_match "Thank you for joining PaintHoarder", mail.body.encoded
  end
end
