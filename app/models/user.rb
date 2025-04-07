# frozen_string_literal: true

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
class User < ApplicationRecord
  attr_accessor :login

  normalizes :email, with: ->(email) { email.strip.downcase }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable, :lockable, :confirmable,
    authentication_keys: [:login]

  ## ASSOCIATIONS
  has_many :user_paints
  has_many :paints, through: :user_paints

  # Store user preferences in a JSON column
  store_accessor :preferences, :similar_paint_brand_ids

  validates :username, presence: true, length: {maximum: 20}, username: true, uniqueness: {case_sensitive: false}

  def to_s
    username
  end

  def name
    username
  end

  def after_confirmation
    UserMailer.with(user: self).welcome.deliver_later
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      # when allowing distinct User records with, e.g., "username" and "UserName"...
      where(conditions).where(["username = :value OR lower(email) = :value", {value: login}]).first
    else
      where(conditions).first
    end
  end

  # Get the brand IDs for similar paint filtering
  # If not set, defaults to the brands of paints the user owns
  def similar_paint_brand_ids
    stored_ids = preferences&.dig("similar_paint_brand_ids")
    return stored_ids if stored_ids.present?

    # Default to brands of paints the user owns
    paints.joins(:brand).distinct.pluck("brands.id").map(&:to_s)
  end

  # Set the brand IDs for similar paint filtering
  def similar_paint_brand_ids=(ids)
    self.preferences ||= {}
    self.preferences["similar_paint_brand_ids"] = Array(ids).map(&:to_s).uniq
    save
  end
end
