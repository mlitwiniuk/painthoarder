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

  test "converts pure red RGB to correct HSV values" do
    paint = create(:paint, red: 255, green: 0, blue: 0)
    hsv = paint.hsv_values

    assert_equal 0.0, hsv[:h]
    assert_equal 100.0, hsv[:s]
    assert_equal 100.0, hsv[:v]
  end

  test "converts pure green RGB to correct HSV values" do
    paint = create(:paint, red: 0, green: 255, blue: 0)
    hsv = paint.hsv_values

    assert_equal 120.0, hsv[:h]
    assert_equal 100.0, hsv[:s]
    assert_equal 100.0, hsv[:v]
  end

  test "converts pure blue RGB to correct HSV values" do
    paint = create(:paint, red: 0, green: 0, blue: 255)
    hsv = paint.hsv_values

    assert_equal 240.0, hsv[:h]
    assert_equal 100.0, hsv[:s]
    assert_equal 100.0, hsv[:v]
  end

  test "converts black RGB to correct HSV values" do
    paint = create(:paint, red: 0, green: 0, blue: 0)
    hsv = paint.hsv_values

    assert_equal 0.0, hsv[:h]
    assert_equal 0.0, hsv[:s]
    assert_equal 0.0, hsv[:v]
  end

  test "converts white RGB to correct HSV values" do
    paint = create(:paint, red: 255, green: 255, blue: 255)
    hsv = paint.hsv_values

    assert_equal 0.0, hsv[:h]
    assert_equal 0.0, hsv[:s]
    assert_equal 100.0, hsv[:v]
  end

  test "converts gray RGB to correct HSV values" do
    paint = create(:paint, red: 128, green: 128, blue: 128)
    hsv = paint.hsv_values

    assert_equal 0.0, hsv[:h]
    assert_equal 0.0, hsv[:s]
    assert_in_delta 50.2, hsv[:v], 0.1
  end

  test "converts cyan RGB to correct HSV values" do
    paint = create(:paint, red: 0, green: 255, blue: 255)
    hsv = paint.hsv_values

    assert_equal 180.0, hsv[:h]
    assert_equal 100.0, hsv[:s]
    assert_equal 100.0, hsv[:v]
  end

  test "converts magenta RGB to correct HSV values" do
    paint = create(:paint, red: 255, green: 0, blue: 255)
    hsv = paint.hsv_values

    assert_equal 300.0, hsv[:h]
    assert_equal 100.0, hsv[:s]
    assert_equal 100.0, hsv[:v]
  end

  test "converts yellow RGB to correct HSV values" do
    paint = create(:paint, red: 255, green: 255, blue: 0)
    hsv = paint.hsv_values

    assert_equal 60.0, hsv[:h]
    assert_equal 100.0, hsv[:s]
    assert_equal 100.0, hsv[:v]
  end

  test "converts complex color RGB to correct HSV values" do
    # Testing RGB(128, 64, 192) which should be purple-ish
    paint = create(:paint, red: 128, green: 64, blue: 192)
    hsv = paint.hsv_values

    # Expected: H=270, S=66.7%, V=75.3%
    assert_in_delta 270.0, hsv[:h], 1.0
    assert_in_delta 66.7, hsv[:s], 1.0
    assert_in_delta 75.3, hsv[:v], 1.0
  end

  test "handles edge case with negative hue calculation" do
    # Test a color that might produce negative hue in intermediate calculations
    paint = create(:paint, red: 192, green: 64, blue: 128)
    hsv = paint.hsv_values

    # Should normalize negative hue to positive range
    assert hsv[:h] >= 0.0
    assert hsv[:h] <= 360.0
  end

  test "returns values with correct precision" do
    paint = create(:paint, red: 123, green: 234, blue: 45)
    hsv = paint.hsv_values

    # All values should be rounded to 1 decimal place
    assert_equal hsv[:h], hsv[:h].round(1)
    assert_equal hsv[:s], hsv[:s].round(1)
    assert_equal hsv[:v], hsv[:v].round(1)
  end

  test "categorizes pure colors correctly" do
    red_paint = create(:paint, red: 255, green: 0, blue: 0)
    assert_equal "Red", red_paint.color_category

    green_paint = create(:paint, red: 0, green: 255, blue: 0)
    assert_equal "Green", green_paint.color_category

    blue_paint = create(:paint, red: 0, green: 0, blue: 255)
    assert_equal "Royal Blue", blue_paint.color_category
  end

  test "categorizes achromatic colors correctly" do
    black_paint = create(:paint, red: 0, green: 0, blue: 0)
    assert_equal "Black", black_paint.color_category

    white_paint = create(:paint, red: 255, green: 255, blue: 255)
    assert_equal "White", white_paint.color_category

    gray_paint = create(:paint, red: 128, green: 128, blue: 128)
    assert_equal "Gray", gray_paint.color_category

    dark_gray_paint = create(:paint, red: 64, green: 64, blue: 64)
    assert_equal "Dark Gray", dark_gray_paint.color_category

    light_gray_paint = create(:paint, red: 192, green: 192, blue: 192)
    assert_equal "Light Gray", light_gray_paint.color_category
  end

  test "categorizes orange colors correctly" do
    orange_paint = create(:paint, red: 255, green: 128, blue: 0)
    assert_equal "Orange", orange_paint.color_category
  end

  test "categorizes yellow colors correctly" do
    yellow_paint = create(:paint, red: 255, green: 255, blue: 0)
    assert_equal "Gold", yellow_paint.color_category
  end

  test "categorizes cyan colors correctly" do
    cyan_paint = create(:paint, red: 0, green: 255, blue: 255)
    assert_equal "Turquoise", cyan_paint.color_category
  end

  test "categorizes purple colors correctly" do
    purple_paint = create(:paint, red: 128, green: 0, blue: 128)
    assert_equal "Purple", purple_paint.color_category
  end

  test "categorizes dark colors correctly" do
    dark_red_paint = create(:paint, red: 50, green: 0, blue: 0)
    assert_equal "Maroon", dark_red_paint.color_category

    dark_blue_paint = create(:paint, red: 0, green: 0, blue: 50)
    assert_equal "Dark Blue", dark_blue_paint.color_category
  end

  test "categorizes pastel colors correctly" do
    # Low saturation, high value colors
    beige_paint = create(:paint, red: 245, green: 235, blue: 220)
    # This should be categorized as beige-like color due to low saturation
    result = beige_paint.color_category
    assert result.is_a?(String)
    assert result.length > 0
  end

  test "brand_name returns associated brand name" do
    brand = create(:brand, name: "Test Brand")
    product_line = create(:product_line, brand: brand, name: "Test Line")
    paint = create(:paint, product_line: product_line)

    assert_equal "Test Brand", paint.brand_name
  end

  test "product_line_name returns associated product line name" do
    product_line = create(:product_line, name: "Test Product Line")
    paint = create(:paint, product_line: product_line)

    assert_equal "Test Product Line", paint.product_line_name
  end

  test "name_code_normalized returns normalized string" do
    paint = create(:paint, name: "Test Paint!", code: "TP-123")
    normalized = paint.name_code_normalized

    assert_equal "Test Paint TP123", normalized
    # Should remove non-alphanumeric characters except spaces
    assert_not_includes normalized, "!"
    assert_not_includes normalized, "-"
  end

  test "owned_count returns correct count" do
    paint = create(:paint)
    user1 = create(:user)
    user2 = create(:user)
    user3 = create(:user)

    create(:user_paint, paint: paint, user: user1, status: :owned)
    create(:user_paint, paint: paint, user: user2, status: :owned)
    create(:user_paint, paint: paint, user: user3, status: :wishlist)

    assert_equal 2, paint.owned_count
  end

  test "wishlist_count returns correct count" do
    paint = create(:paint)
    user1 = create(:user)
    user2 = create(:user)
    user3 = create(:user)

    create(:user_paint, paint: paint, user: user1, status: :wishlist)
    create(:user_paint, paint: paint, user: user2, status: :wishlist)
    create(:user_paint, paint: paint, user: user3, status: :owned)

    assert_equal 2, paint.wishlist_count
  end

  test "avoid_count returns correct count" do
    paint = create(:paint)
    user1 = create(:user)
    user2 = create(:user)
    user3 = create(:user)

    create(:user_paint, paint: paint, user: user1, status: :avoid)
    create(:user_paint, paint: paint, user: user2, status: :owned)
    create(:user_paint, paint: paint, user: user3, status: :wishlist)

    assert_equal 1, paint.avoid_count
  end

  test "total_users_count returns correct count" do
    paint = create(:paint)
    user1 = create(:user)
    user2 = create(:user)
    user3 = create(:user)

    create(:user_paint, paint: paint, user: user1, status: :owned)
    create(:user_paint, paint: paint, user: user2, status: :wishlist)
    create(:user_paint, paint: paint, user: user3, status: :avoid)

    assert_equal 3, paint.total_users_count
  end

  test "collection_stats returns complete statistics hash" do
    paint = create(:paint)
    user1 = create(:user)
    user2 = create(:user)
    user3 = create(:user)

    create(:user_paint, paint: paint, user: user1, status: :owned)
    create(:user_paint, paint: paint, user: user2, status: :owned)
    create(:user_paint, paint: paint, user: user3, status: :wishlist)

    stats = paint.collection_stats

    assert_equal 2, stats[:owned]
    assert_equal 1, stats[:wishlist]
    assert_equal 0, stats[:avoid]
    assert_equal 3, stats[:total]
  end

  test "collection_stats with no user_paints returns zeros" do
    paint = create(:paint)
    stats = paint.collection_stats

    assert_equal 0, stats[:owned]
    assert_equal 0, stats[:wishlist]
    assert_equal 0, stats[:avoid]
    assert_equal 0, stats[:total]
  end

  test "hex_color is set before save" do
    paint = build(:paint, red: 255, green: 128, blue: 64)
    paint.hex_color = nil

    paint.save!

    assert_equal "#ff8040", paint.hex_color.downcase
  end

  test "hex_color handles zero values correctly" do
    paint = create(:paint, red: 0, green: 15, blue: 255)

    assert_equal "#000fff", paint.hex_color.downcase
  end

  test "hex_color pads single digit values with zero" do
    paint = create(:paint, red: 1, green: 16, blue: 255)

    assert_equal "#0110ff", paint.hex_color.downcase
  end

  test "handles RGB boundary values correctly" do
    # Test minimum values
    paint_min = create(:paint, red: 0, green: 0, blue: 0)
    assert paint_min.valid?
    assert_equal "#000000", paint_min.hex_color.downcase

    # Test maximum values
    paint_max = create(:paint, red: 255, green: 255, blue: 255)
    assert paint_max.valid?
    assert_equal "#ffffff", paint_max.hex_color.downcase
  end

  test "rejects invalid RGB values" do
    # Test negative values
    paint = build(:paint, red: -1, green: 0, blue: 0)
    assert_not paint.valid?
    assert paint.errors[:red].present?

    # Test values over 255
    paint = build(:paint, red: 256, green: 0, blue: 0)
    assert_not paint.valid?
    assert paint.errors[:red].present?

    # Test non-integer values
    paint = build(:paint, red: 255.5, green: 0, blue: 0)
    assert_not paint.valid?
    assert paint.errors[:red].present?
  end

  test "requires all RGB values to be present" do
    paint = build(:paint, red: nil, green: 0, blue: 0)
    assert_not paint.valid?
    assert paint.errors[:red].present?

    paint = build(:paint, red: 0, green: nil, blue: 0)
    assert_not paint.valid?
    assert paint.errors[:green].present?

    paint = build(:paint, red: 0, green: 0, blue: nil)
    assert_not paint.valid?
    assert paint.errors[:blue].present?
  end

  test "lab colour is populated before save" do
    paint = create(:paint, red: 255, green: 255, blue: 255)

    assert_in_delta 100.0, paint.lab_l, 0.01
    assert_in_delta 0.0, paint.lab_a, 0.05
    assert_in_delta 0.0, paint.lab_b, 0.05
    assert_equal [paint.lab_l, paint.lab_a, paint.lab_b], paint.lab
  end

  test "updating RGB values recomputes lab colour" do
    paint = create(:paint, red: 255, green: 255, blue: 255)
    white_lab = paint.lab

    paint.update(red: 0, green: 0, blue: 0)

    assert_not_equal white_lab, paint.lab
    assert_equal [0.0, 0.0, 0.0], paint.lab
  end
end
