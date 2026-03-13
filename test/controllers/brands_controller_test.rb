require "test_helper"

class BrandsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @brand = create(:brand, name: "Test Brand")
    @product_line = create(:product_line, brand: @brand, name: "Test Line")
    @paint = create(:paint, product_line: @product_line, name: "Test Red", code: "TR1", red: 255, green: 0, blue: 0)
  end

  test "should get index" do
    get brands_url
    assert_response :success
    assert_includes response.body, @brand.name
  end

  test "index shows brand count" do
    get brands_url
    assert_response :success
    assert_select "h1", /Paint Brands/
  end

  test "should get show" do
    get brand_url(@brand)
    assert_response :success
    assert_includes response.body, @brand.name
    assert_includes response.body, @product_line.name
  end

  test "show displays product lines" do
    get brand_url(@brand)
    assert_response :success
    assert_includes response.body, @product_line.name
  end

  test "show uses friendly slug" do
    get brand_url(@brand.slug)
    assert_response :success
  end
end
