# == Schema Information
#
# Table name: pages
#
#  id         :integer          not null, primary key
#  content    :text
#  prefrences :json
#  published  :boolean          default(FALSE)
#  slug       :string
#  status     :integer          default("draft"), not null
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_pages_on_slug  (slug) UNIQUE
#
class Page < ApplicationRecord
  # Attributes
  extend FriendlyId
  friendly_id :title, use: :slugged
  enum :status, {draft: 0, issued: 1, archived: 99}

  # Associations

  # Validations
  validates :title, presence: true, uniqueness: true, length: {minimum: 5, maximum: 150}
  validates :content, presence: true

  has_rich_text :content

  # Callbacks
end
