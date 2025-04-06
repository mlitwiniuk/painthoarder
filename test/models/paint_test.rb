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
require "test_helper"

class PaintTest < ActiveSupport::TestCase
  context "validations" do
    should validate_presence_of(:name)
    should validate_presence_of(:code)
    should validate_presence_of(:red)
    should validate_presence_of(:green)
    should validate_presence_of(:blue)

    should validate_numericality_of(:red).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(255)
    should validate_numericality_of(:green).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(255)
    should validate_numericality_of(:blue).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(255)
  end

  context "associations" do
    should belong_to(:product_line)
    should have_one(:brand).through(:product_line)
    should have_many(:user_paints)
  end

  test "hex_color is automatically generated from RGB values" do
    paint = create(:red_paint)
    assert_equal "#ff0000", paint.hex_color.downcase

    paint = create(:green_paint)
    assert_equal "#00ff00", paint.hex_color.downcase
  end

  test "updating RGB values updates hex_color" do
    paint = create(:paint, red: 255, green: 0, blue: 0)
    assert_equal "#ff0000", paint.hex_color.downcase

    paint.update(red: 0, green: 255, blue: 0)
    assert_equal "#00ff00", paint.hex_color.downcase
  end

  test "can create a paint with attached image" do
    paint = create(:paint, :with_image)
    assert paint.image.attached?
  end
end
