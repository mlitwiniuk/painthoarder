# == Schema Information
#
# Table name: product_lines
#
#  id          :integer          not null, primary key
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  brand_id    :integer          not null
#
# Indexes
#
#  index_product_lines_on_brand_id  (brand_id)
#
# Foreign Keys
#
#  brand_id  (brand_id => brands.id)
#
class ProductLine < ApplicationRecord
  ## FRIENDLY ID
  extend FriendlyId
  friendly_id :name, use: [:slugged, :scoped], scope: :brand

  ## ASSOCIATIONS
  belongs_to :brand
  has_many :paints, dependent: :destroy
  has_many :product_line_similarities, dependent: :destroy
  has_many :similar_product_lines, through: :product_line_similarities

  ## VALIDATIONS
  validates :name, presence: true

  ## RANSACK CONFIG
  # Define which attributes can be used for searching
  def self.ransackable_attributes(auth_object = nil)
    ["brand_id", "created_at", "description", "id", "name", "updated_at"]
  end

  # Define which associations can be used for searching
  def self.ransackable_associations(auth_object = nil)
    ["brand", "paints"]
  end

  def self.ransortable_attributes(auth_object = nil)
    ["name"]
  end

  def self.ransortable_associations(auth_object = nil)
    ["brand"]
  end

  def to_s
    [brand.name, name].join(" - ")
  end
end
