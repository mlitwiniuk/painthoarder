# == Schema Information
#
# Table name: paints
#
#  id              :integer          not null, primary key
#  blue            :integer
#  code            :string
#  green           :integer
#  hex_color       :string
#  name            :string
#  red             :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_line_id :integer          not null
#
# Indexes
#
#  index_paints_on_product_line_id  (product_line_id)
#
# Foreign Keys
#
#  product_line_id  (product_line_id => product_lines.id)
#
class Paint < ApplicationRecord
  ## CONCERNS
  include SqliteSearch
  search_scope(:name, :code, :brand_name, :product_line_name, includes: [:brand, :product_line])

  ## ATTRIBUTES
  has_one_attached :image

  ## ASSOCIATIONS
  belongs_to :product_line
  has_one :brand, through: :product_line
  has_many :user_paints, dependent: :destroy

  ## VALIDATIONS
  validates :name, :code, presence: true
  validates :red, :green, :blue, presence: true,
    numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 255}

  ## BEFORE & AFTER
  before_save :set_hex_color

  def brand_name
    brand.name
  end

  def product_line_name
    product_line.name
  end

  ## RANSACK CONFIG
  # Define which attributes can be used for searching
  def self.ransackable_attributes(auth_object = nil)
    ["blue", "code", "created_at", "green", "hex_color", "id", "name", "product_line_id", "red", "updated_at"]
  end

  # Define which associations can be used for searching
  def self.ransackable_associations(auth_object = nil)
    ["brand", "product_line", "user_paints"]
  end

  # Make custom sort work for associations
  def self.ransortable_attributes(auth_object = nil)
    ransackable_attributes(auth_object) + ["product_line_brand_name"]
  end

  private

  ## Callbacks
  def set_hex_color
    self.hex_color = "##{red.to_s(16).rjust(2, "0")}#{green.to_s(16).rjust(2, "0")}#{blue.to_s(16).rjust(2, "0")}"
  end
end
