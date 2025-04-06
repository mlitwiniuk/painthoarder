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
require "test_helper"

class ProductLineTest < ActiveSupport::TestCase
  context "validations" do
    should validate_presence_of(:name)
  end

  context "associations" do
    should belong_to(:brand)
    should have_many(:paints)
  end

  test "can create a product line with valid attributes" do
    product_line = build(:product_line)
    assert product_line.valid?
    assert_difference('ProductLine.count') do
      product_line.save
    end
  end
end
