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

  ## ASSOCIATIONS
  belongs_to :brand
  has_many :paints, dependent: :destroy

  ## VALIDATIONS
  validates :name, presence: true


  def to_s
    [brand.name, name].join(' - ')
  end
end
