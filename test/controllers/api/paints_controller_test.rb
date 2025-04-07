require "test_helper"

class Api::PaintsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = FactoryBot.create(:confirmed_user)
    @product_line = FactoryBot.create(:product_line)
    @paint1 = FactoryBot.create(:paint,
      product_line: @product_line,
      name: "Abaddon Black",
      code: "AB01",
      hex_color: "#000000")
    @paint2 = FactoryBot.create(:paint,
      product_line: @product_line,
      name: "White Scar",
      code: "WS02",
      hex_color: "#FFFFFF")
    @other_product_line = FactoryBot.create(:product_line)
    @other_paint = FactoryBot.create(:paint,
      product_line: @other_product_line,
      name: "Red Gore",
      code: "RG03",
      hex_color: "#CC0000")
  end

  test "should require authentication for index" do
    get api_paints_url, as: :json
    assert_response :unauthorized
  end

  test "should require authentication for show" do
    get api_paint_url(@paint1), as: :json
    assert_response :unauthorized
  end

  test "should get all paints" do
    sign_in @user
    get api_paints_url, as: :json
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal 3, response_data.length

    # Check JSON structure
    assert_equal({
      "id" => @paint1.id,
      "text" => "Abaddon Black (AB01)",
      "color" => "#808080",
      "product_line_id" => @paint1.product_line_id
    }, response_data.find { |p| p["id"] == @paint1.id })
  end

  test "should get paints for specific product line" do
    sign_in @user
    get api_paints_url, params: {product_line_id: @product_line.id}, as: :json
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal 2, response_data.length

    paint_ids = response_data.map { |p| p["id"] }
    assert_includes paint_ids, @paint1.id
    assert_includes paint_ids, @paint2.id
    refute_includes paint_ids, @other_paint.id
  end

  test "should filter paints by name query" do
    sign_in @user
    get api_paints_url, params: {query: "Black"}, as: :json
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal 1, response_data.length
    assert_equal @paint1.id, response_data.first["id"]
  end

  test "should filter paints by code query" do
    sign_in @user
    get api_paints_url, params: {query: "WS02"}, as: :json
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal 1, response_data.length
    assert_equal @paint2.id, response_data.first["id"]
  end

  test "should get specific paint" do
    sign_in @user
    get api_paint_url(@paint1), as: :json
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal({
      "id" => @paint1.id,
      "name" => "Abaddon Black",
      "code" => "AB01",
      "color" => "#808080",
      "brand_name" => @paint1.brand_name,
      "product_line_name" => @paint1.product_line_name
    }, response_data)
  end
end
