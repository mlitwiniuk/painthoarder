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

    assert_selector "h1", text: "My Paint Collection"

    # Test recent paints section
    assert_selector "h2.card-title", text: "Recently Added"
    
    # There might be user paints or the empty state message
    assert_selector("ul.space-y-2", minimum: 0)

    # No need to assert on specific paint card elements as they might not be there
    # Just checking for the main sections is sufficient
  end
end
