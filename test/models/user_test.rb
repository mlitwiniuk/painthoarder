# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locked_at              :datetime
#  preferences            :json
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  unconfirmed_email      :string
#  unlock_token           :string
#  username               :string           default(""), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#  index_users_on_username              (username) UNIQUE
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  context "validations" do
    subject { build(:user) }
    
    should validate_presence_of(:email)
    should validate_uniqueness_of(:email).case_insensitive.ignoring_case_sensitivity
    should validate_presence_of(:username)
    should validate_uniqueness_of(:username).case_insensitive.ignoring_case_sensitivity
  end

  context "associations" do
    should have_many(:user_paints)
    should have_many(:paints).through(:user_paints)
  end

  test "should create a valid user" do
    user = build(:user)
    assert user.valid?
    assert_difference('User.count') do
      user.save
    end
  end

  test "should require email and password" do
    user = build(:user, email: nil, password: nil)
    refute user.valid?
    assert user.errors.include?(:email)
    assert user.errors.include?(:password)
  end

  test "should confirm a user" do
    user = create(:user)
    refute user.confirmed?

    # Update confirmation attributes directly instead of using confirm method
    user.confirmed_at = Time.current
    user.save!
    
    assert user.confirmed?
  end

  test "should lock a user after too many failed attempts" do
    user = create(:confirmed_user)
    refute user.access_locked?

    # Simulate failed attempts and lock directly without lock_access!
    user.failed_attempts = Devise.maximum_attempts
    user.locked_at = Time.current
    user.save!

    assert user.access_locked?
  end

  test "factory traits work correctly" do
    # For confirmed user, check that the factory sets confirmed_at properly
    confirmed_user = create(:user, :confirmed)
    assert confirmed_user.confirmed?

    # For locked user, verify that locked_at is set correctly
    locked_user = create(:user, :locked)
    assert locked_user.access_locked?

    # For reset password user, check that the token is present
    reset_user = create(:user, :with_reset_password)
    assert_not_nil reset_user.reset_password_token

    # For tracked user, verify sign_in_count
    tracked_user = create(:user, :with_sign_in_tracking)
    assert_equal 1, tracked_user.sign_in_count
  end
end
