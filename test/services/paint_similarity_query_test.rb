require "test_helper"

class PaintSimilarityQueryTest < ActiveSupport::TestCase
  setup do
    @brand = create(:brand, name: "Brand A")
    @line = create(:product_line, brand: @brand, name: "Line A")

    @source = paint(255, 0, 0, "Source Red")
    @near = paint(250, 8, 8, "Near Red")
    @nearer = paint(252, 4, 4, "Nearer Red")
    @mid = paint(190, 45, 45, "Muted Red")
    @far = paint(0, 0, 255, "Pure Blue")
  end

  test "color strategy ranks closest perceptual matches first" do
    ranked = PaintSimilarityQuery.new(@source, strategy: "color").ranked
    ids = ranked.map(&:first)

    assert_equal @nearer.id, ids.first, "closest colour should rank first"
    assert_includes ids, @near.id
    assert_includes ids, @mid.id
  end

  test "color strategy excludes paints beyond the similarity threshold" do
    ranked = PaintSimilarityQuery.new(@source, strategy: "color").ranked
    ids = ranked.map(&:first)

    assert_not_includes ids, @far.id, "a wildly different colour must be filtered out"
    assert_not_includes ids, @source.id, "the source paint must not appear in its own results"
  end

  test "scores are ascending CIEDE2000 distances" do
    ranked = PaintSimilarityQuery.new(@source, strategy: "color").ranked
    scores = ranked.map(&:last)

    assert_equal scores.sort, scores
    assert scores.all? { |s| s <= PaintSimilarityQuery::COLOR_THRESHOLD }
  end

  test "hue strategy keeps the same hue family and drops other hues" do
    dark_red = paint(90, 0, 0, "Dark Red")
    green = paint(0, 200, 0, "Bright Green")

    ids = PaintSimilarityQuery.new(@source, strategy: "hue").ranked.map(&:first)

    assert_includes ids, dark_red.id, "a darker shade of the same hue belongs to the family"
    assert_not_includes ids, green.id, "a different hue is not in the family"
  end

  test "brand filter restricts candidates to the given brands" do
    other_brand = create(:brand, name: "Brand B")
    other_line = create(:product_line, brand: other_brand, name: "Line B")
    other_red = create(:paint, product_line: other_line, red: 248, green: 6, blue: 6,
      name: "Other Brand Red", code: "OBR")

    ids = PaintSimilarityQuery.new(@source, strategy: "color", brand_ids: [@brand.id]).ranked.map(&:first)

    assert_includes ids, @near.id
    assert_not_includes ids, other_red.id
  end

  test "related product lines win ties within the boost tolerance band" do
    related_line = create(:product_line, brand: @brand, name: "Related Line")
    create(:product_line_similarity, product_line: @line, similar_product_line: related_line)

    plain_line = create(:product_line, brand: @brand, name: "Unrelated Line")

    grey_source = create(:paint, product_line: @line, red: 100, green: 100, blue: 100,
      name: "Grey Source", code: "GS")
    # The related candidate is slightly farther in ΔE than the plain one, but
    # both fall inside one BOOST_TOLERANCE bucket, so the related line wins.
    related = create(:paint, product_line: related_line, red: 102, green: 100, blue: 100,
      name: "Related Grey", code: "RG")
    plain = create(:paint, product_line: plain_line, red: 101, green: 100, blue: 100,
      name: "Plain Grey", code: "PG")

    ranked = PaintSimilarityQuery.new(grey_source, strategy: "color").ranked
    scores = ranked.to_h

    assert scores[related.id] > scores[plain.id],
      "related candidate must be the farther of the two for the test to be meaningful"
    assert scores[related.id] < PaintSimilarityQuery::BOOST_TOLERANCE
    assert scores[plain.id] < PaintSimilarityQuery::BOOST_TOLERANCE
    assert ranked.map(&:first).index(related.id) < ranked.map(&:first).index(plain.id),
      "related product line should be boosted ahead within the tolerance band"
  end

  test "page slices the ranked list and reports whether more remain" do
    query = PaintSimilarityQuery.new(@source, strategy: "color")
    total = query.total_count
    assert total >= 3

    first_page = query.page(1, 2)
    assert_equal 2, first_page.size
    assert first_page.all? { |row| row[:paint].is_a?(Paint) && row[:score].is_a?(Numeric) }
    assert query.more_after?(1, 2)

    last_page = query.page((total / 2.0).ceil, 2)
    assert_not query.more_after?((total / 2.0).ceil, 2)
  end

  test "ranked results are cached and not recomputed" do
    with_memory_cache do
      first = PaintSimilarityQuery.new(@source, strategy: "color").ranked

      ColorMath.expects(:ciede2000).never
      second = PaintSimilarityQuery.new(@source, strategy: "color").ranked

      assert_equal first, second
    end
  end

  private

  def paint(red, green, blue, name)
    create(:paint, product_line: @line, red: red, green: green, blue: blue,
      name: name, code: name.delete(" "))
  end

  def with_memory_cache
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original
  end
end
