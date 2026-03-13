require "test_helper"

class ProductLinesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @brand = create(:brand, name: "Test Brand")
    @product_line = create(:product_line, brand: @brand, name: "Test Line")
    @paint = create(:paint, product_line: @product_line, name: "Test Red", code: "TR1", red: 255, green: 0, blue: 0)
  end

  test "should get show" do
    get brand_product_line_url(@brand, @product_line)
    assert_response :success
    assert_includes response.body, @product_line.name
    assert_includes response.body, @paint.name
  end

  test "show displays breadcrumbs" do
    get brand_product_line_url(@brand, @product_line)
    assert_response :success
    assert_includes response.body, @brand.name
  end

  test "show supports color filter" do
    get brand_product_line_url(@brand, @product_line, color: "red")
    assert_response :success
  end

  test "show uses friendly slug" do
    get brand_product_line_url(@brand.slug, @product_line.slug)
    assert_response :success
  end
end
