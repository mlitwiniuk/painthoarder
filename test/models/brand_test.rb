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
require "test_helper"

class BrandTest < ActiveSupport::TestCase
  context "validations" do
    should validate_presence_of(:name)
    should validate_uniqueness_of(:name)
  end

  context "associations" do
    should have_many(:product_lines)
    should have_many(:paints).through(:product_lines)
  end

  test "can create a brand with valid attributes" do
    brand = build(:brand)
    assert brand.valid?
    assert_difference("Brand.count") do
      brand.save
    end
  end

  test "can attach a logo" do
    brand = create(:brand, :with_logo)
    assert brand.logo.attached?
  end
end
