require "test_helper"

class DirectoryPaintsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @brand = create(:brand, name: "Test Brand")
    @product_line = create(:product_line, brand: @brand, name: "Test Line")
    @paint = create(:paint, product_line: @product_line, name: "Test Red", code: "TR1", red: 255, green: 0, blue: 0)
  end

  test "should get show via slugs" do
    get brand_product_line_paint_url(@brand, @product_line, @paint.slug)
    assert_response :success
    assert_includes response.body, @paint.name
  end

  test "should get show via numeric paint id" do
    get brand_product_line_paint_url(@brand, @product_line, @paint.id)
    assert_response :success
  end

  test "show displays paint details for signed in user" do
    user = create(:user, :confirmed)
    sign_in user
    get brand_product_line_paint_url(@brand, @product_line, @paint.slug)
    assert_response :success
    assert_includes response.body, @paint.name
  end

  test "show links back to product line" do
    get brand_product_line_paint_url(@brand, @product_line, @paint.slug)
    assert_response :success
    assert_includes response.body, brand_product_line_path(@brand, @product_line)
  end

  test "PaintsController#show redirects to directory URL" do
    get paint_url(@paint)
    assert_response :moved_permanently
    assert_redirected_to brand_product_line_paint_path(@brand, @product_line, @paint.slug)
  end
end
