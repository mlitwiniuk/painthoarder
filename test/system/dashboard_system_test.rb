require "application_system_test_case"

class DashboardSystemTest < ApplicationSystemTestCase
  setup do
    @user = create(:confirmed_user)
    @brand = create(:brand, name: "Test Brand")
    @product_line = create(:product_line, brand: @brand, name: "Test Line")
    @paint1 = create(:paint, name: "Test Paint 1", code: "TP1", product_line: @product_line, hex_color: "#ff0000")
    @paint2 = create(:paint, name: "Test Paint 2", code: "TP2", product_line: @product_line, hex_color: "#00ff00")

    # Create user paints
    @user_paint1 = create(:user_paint, user: @user, paint: @paint1)
    @user_paint2 = create(:user_paint, user: @user, paint: @paint2)

    login_as(@user, scope: :user)
  end

  test "viewing dashboard with paint collections" do
    visit user_root_path

    assert_selector "h1", text: "Welcome back, #{@user.name}"
    assert_selector "h2", text: "Recently Added Paints"
    assert_text @paint1.name
    assert_text @paint2.name
    click_on "View My Collection"
    assert_selector "h1", text: "My Paint Collection"
  end
end
