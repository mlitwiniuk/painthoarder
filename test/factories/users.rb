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
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "username#{n}" }
    password { "password123" }
    password_confirmation { "password123" }

    # By default, users are not confirmed

    trait :confirmed do
      confirmed_at { Time.current }
    end

    trait :locked do
      locked_at { Time.current }
      failed_attempts { 10 }
    end

    trait :with_reset_password do
      reset_password_token { SecureRandom.urlsafe_base64 }
      reset_password_sent_at { Time.current }
    end

    trait :with_sign_in_tracking do
      current_sign_in_at { Time.current }
      last_sign_in_at { Time.current - 1.day }
      current_sign_in_ip { "127.0.0.1" }
      last_sign_in_ip { "127.0.0.1" }
      sign_in_count { 1 }
    end

    factory :confirmed_user do
      confirmed_at { Time.current }
    end
  end
end
