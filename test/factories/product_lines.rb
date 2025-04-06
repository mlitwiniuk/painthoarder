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
FactoryBot.define do
  factory :product_line do
    sequence(:name) { |n| "Product Line #{n}" }
    description { "A detailed description of the product line" }
    association :brand
  end
end
