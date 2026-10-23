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

  test "catalogue shows counts, colour chips and paint cards" do
    get paints_url

    assert_response :success
    assert_select "h1", text: "Catalogue"
    assert_select "input[name=search][placeholder*='paints from']"
    assert_select "a.chip[aria-pressed]", minimum: ColorCategorization::COLOR_CATEGORIES.size
    assert_select "#paint-card-#{@source.id}"
  end

  test "catalogue hides owned paints when asked" do
    user = create(:confirmed_user)
    create(:user_paint, user: user, paint: @source, status: :owned)
    sign_in user

    get paints_url, params: {hide_owned: "1"}

    assert_response :success
    assert_select "#paint-card-#{@source.id}", count: 0
    assert_select "#paint-card-#{@match.id}"
  end

  test "catalogue load more responds with a turbo stream" do
    get paints_url, params: {page: 1}, headers: {"Accept" => "text/vnd.turbo-stream.html"}

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "catalog-grid"
  end

  test "collection_status adds, changes and removes a paint" do
    user = create(:confirmed_user)
    sign_in user

    patch collection_status_paint_url(@source), params: {status: "wishlist"}, as: :turbo_stream
    assert_response :success
    assert_equal "wishlist", user.user_paints.find_by(paint: @source).status
    assert_includes response.body, "collection-options-#{@source.id}"

    patch collection_status_paint_url(@source), params: {status: "owned"}
    assert_response :redirect
    assert_equal "owned", user.user_paints.find_by(paint: @source).status

    patch collection_status_paint_url(@source), params: {status: "none"}, as: :turbo_stream
    assert_nil user.user_paints.find_by(paint: @source)
  end

  test "collection_status rejects unknown statuses and guests" do
    patch collection_status_paint_url(@source), params: {status: "owned"}
    assert_redirected_to new_user_session_path

    sign_in create(:confirmed_user)
    patch collection_status_paint_url(@source), params: {status: "bogus"}
    assert_response :unprocessable_entity
  end

  test "similar can be widened to all brands" do
    user = create(:confirmed_user)
    sign_in user

    get similar_paint_url(@source, brand_ids: "all")

    assert_response :success
    assert_equal ["all"], user.reload.preferences["similar_paint_brand_ids"]
    assert_includes response.body, @match.name
  end
end
