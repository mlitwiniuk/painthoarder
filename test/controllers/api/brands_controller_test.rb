require "test_helper"

class Api::BrandsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = FactoryBot.create(:confirmed_user)
    @brand1 = FactoryBot.create(:brand, name: "Citadel")
    @brand2 = FactoryBot.create(:brand, name: "Vallejo")
  end

  test "should require authentication" do
    get api_brands_url, as: :json
    assert_response :unauthorized
  end

  test "should get all brands" do
    sign_in @user.reload
    get api_brands_url, as: :json
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal 2, response_data.length

    brands = response_data.map { |brand| brand["text"] }
    assert_includes brands, "Citadel"
    assert_includes brands, "Vallejo"

    # Check JSON structure
    assert_equal({
      "id" => @brand1.id,
      "text" => @brand1.name
    }, response_data.find { |b| b["id"] == @brand1.id })
  end

  test "should filter brands by query" do
    sign_in @user.reload
    get api_brands_url, params: {query: "Cita"}, as: :json
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal 1, response_data.length
    assert_equal @brand1.id, response_data.first["id"]
    assert_equal "Citadel", response_data.first["text"]
  end
end
