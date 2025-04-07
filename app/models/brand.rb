# == Schema Information
#
# Table name: brands
#
#  id         :integer          not null, primary key
#  name       :string
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_brands_on_name  (name) UNIQUE
#
class Brand < ApplicationRecord
  ## ATTRIBUTES
  has_one_attached :logo

  ## ASSOCIATIONS
  has_many :product_lines, dependent: :destroy
  has_many :paints, through: :product_lines

  ## VALIDATIONS
  validates :name, presence: true, uniqueness: true

  ## RANSACK CONFIG
  # Define which attributes can be used for searching
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "name", "updated_at", "url"]
  end

  # Define which associations can be used for searching
  def self.ransackable_associations(auth_object = nil)
    ["paints", "product_lines"]
  end

  def to_s
    name
  end
end
