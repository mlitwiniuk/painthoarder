require "test_helper"

class PaintsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @brand = create(:brand, name: "Test Brand")
    @line = create(:product_line, brand: @brand, name: "Test Line")
    @source = create(:paint, product_line: @line, red: 255, green: 0, blue: 0,
      name: "Source Red", code: "SR1")
    @match = create(:paint, product_line: @line, red: 248, green: 7, blue: 7,
      name: "Close Red", code: "CR1")
  end

  test "similar returns closest-match results by default" do
    get similar_paint_url(@source)

    assert_response :success
    assert_includes response.body, @match.name
    assert_includes response.body, "ΔE"
  end

  test "similar supports the hue strategy" do
    get similar_paint_url(@source, similar_type: "hue")

    assert_response :success
    assert_includes response.body, "hue family"
  end

  test "similar falls back to the default strategy for unknown types" do
    get similar_paint_url(@source, similar_type: "bogus")

    assert_response :success
    assert_includes response.body, @match.name
  end

  test "similar responds to turbo_stream for pagination" do
    get similar_paint_url(@source, similar_type: "color", page: 1, per_page: 1,
      format: :turbo_stream)

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "similar shows an empty state when nothing is close enough" do
    isolated = create(:paint, product_line: @line, red: 0, green: 128, blue: 0,
      name: "Lonely Green", code: "LG1")

    get similar_paint_url(isolated)

    assert_response :success
    assert_includes response.body, "No Close Matches Found"
  end
end
