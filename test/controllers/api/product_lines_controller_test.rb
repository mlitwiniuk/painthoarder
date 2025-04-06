require "test_helper"

class Api::ProductLinesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @user = FactoryBot.create(:confirmed_user)
    @brand = FactoryBot.create(:brand)
    @product_line1 = FactoryBot.create(:product_line, brand: @brand, name: "Base Colors")
    @product_line2 = FactoryBot.create(:product_line, brand: @brand, name: "Metallics")
    @other_brand = FactoryBot.create(:brand)
    @other_product_line = FactoryBot.create(:product_line, brand: @other_brand, name: "Special Effects")
  end

  test "should require authentication" do
    get api_product_lines_url, as: :json
    assert_response :unauthorized
  end

  # Note: There's a potential bug in the controller with `.non` - it should likely be `.none`
  # This test assumes the controller is fixed to use `.none` when no brand_id is present
  test "should return empty array when no brand_id is provided" do
    sign_in @user
    get api_product_lines_url, as: :json
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_empty response_data
  end

  test "should get product lines for specific brand" do
    sign_in @user
    get api_product_lines_url, params: { brand_id: @brand.id }, as: :json
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal 2, response_data.length

    product_lines = response_data.map { |pl| pl["text"] }
    assert_includes product_lines, "Base Colors"
    assert_includes product_lines, "Metallics"

    # Check JSON structure
    assert_equal({
      "id" => @product_line1.id,
      "text" => @product_line1.name
    }, response_data.find { |pl| pl["id"] == @product_line1.id })
  end

  test "should filter product lines by query" do
    sign_in @user
    get api_product_lines_url, params: { brand_id: @brand.id, query: "Base" }, as: :json
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal 1, response_data.length
    assert_equal @product_line1.id, response_data.first["id"]
    assert_equal "Base Colors", response_data.first["text"]
  end
end
