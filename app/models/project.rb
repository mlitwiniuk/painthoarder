# == Schema Information
#
# Table name: projects
#
#  id             :integer          not null, primary key
#  description    :text
#  secret_token   :string
#  title          :string
#  visibility     :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  cover_photo_id :integer
#  user_id        :integer          not null
#
# Indexes
#
#  index_projects_on_cover_photo_id  (cover_photo_id)
#  index_projects_on_secret_token    (secret_token) UNIQUE
#  index_projects_on_user_id         (user_id)
#
# Foreign Keys
#
#  cover_photo_id  (cover_photo_id => active_storage_attachments.id) ON DELETE => nullify
#  user_id         (user_id => users.id) ON DELETE => cascade
#
class Project < ApplicationRecord
  scope :visibility_restricted_or_public, -> { where(visibility: [:restricted, :public]) }
  attr_accessor :selected_cover_photo_id
  enum :visibility, {private: 0, restricted: 1, public: 2}, prefix: true

  belongs_to :user
  has_many :project_updates, dependent: :destroy
  has_one_attached :cover_photo

  accepts_nested_attributes_for :project_updates, allow_destroy: true

  # Generate secret token for restricted projects
  before_validation :ensure_secret_token
  validates :title, presence: true
  validates :visibility, presence: true
  validates :secret_token, uniqueness: true, allow_nil: true
  validates :cover_photo, content_type: ACCEPTED_CONTENT_TYPES, size: {less_than: 5.megabytes}

  scope :viewable_by, lambda { |user|
    where(
      arel_table[:visibility].eq(visibilities[:public])
      .or(arel_table[:user_id].eq(user.id))
    )
  }

  private

  def ensure_secret_token
    return if secret_token.present?

    self.secret_token = SecureRandom.urlsafe_base64(16) while secret_token.blank? || Project.exists?(secret_token:)
  end
end
