# == Schema Information
#
# Table name: pages
#
#  id         :integer          not null, primary key
#  content    :text
#  prefrences :json
#  published  :boolean          default(FALSE)
#  status     :integer          default("draft"), not null
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Page < ApplicationRecord
  # Attributes
  enum :status, {draft: 0, issued: 1, archived: 99}

  # Associations

  # Validations
  validates :title, presence: true, uniqueness: true, length: {minimum: 5, maximum: 150}
  validates :content, presence: true

  # Callbacks
end
