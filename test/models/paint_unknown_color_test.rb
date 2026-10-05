require "test_helper"

class PaintUnknownColorTest < ActiveSupport::TestCase
  test "unknown RGB stays unknown and is excluded from both similarity strategies" do
    unknown = create(:paint, red: nil, green: nil, blue: nil)
    known = create(:paint)
    assert_nil unknown.hex_color
    assert_nil unknown.hsv_values
    assert_equal "Unknown", unknown.color_category
    assert_equal "Unknown", ColorCategorization.categorize(unknown)
    assert_equal "unknown", unknown.color_source
    %w[color hue].each do |strategy|
      assert_empty PaintSimilarityQuery.new(unknown, strategy: strategy).ranked
      assert_not_includes PaintSimilarityQuery.new(known, strategy: strategy).ranked.map(&:first), unknown.id
    end
  end

  test "partial RGB is invalid and filling or clearing a swatch updates derived colors" do
    paint = build(:paint, red: nil)
    assert_not paint.valid?
    paint = create(:paint, red: nil, green: nil, blue: nil)
    paint.update!(red: 255, green: 0, blue: 0)
    assert_equal "manual", paint.color_source
    assert_equal "#ff0000", paint.hex_color
    assert_not_nil paint.lab_l
    paint.update!(red: nil, green: nil, blue: nil)
    assert_nil paint.hex_color
    assert_nil paint.lab_l
    assert_equal "unknown", paint.color_source
  end

  test "a cached match is hidden after its swatch is removed" do
    source = create(:paint, red: 180, green: 30, blue: 30)
    candidate = create(:paint, red: 180, green: 30, blue: 30)
    query = PaintSimilarityQuery.new(source)
    assert_includes query.ranked.map(&:first), candidate.id
    candidate.update!(red: nil, green: nil, blue: nil)
    assert_empty query.page(1, 12)
  end
end
