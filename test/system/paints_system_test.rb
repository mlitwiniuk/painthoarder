require "application_system_test_case"

class PaintsSystemTest < ApplicationSystemTestCase
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

  test "viewing paint grid on paints index" do
    visit paints_path

    assert_selector "h1", text: /catalogue/i

    assert_select "Sort", with_options: ["Name A–Z", "Brand A–Z", "Newest"]
    assert_selector "[id^='paint-card-']", count: 2
    within("#paint-card-#{@paint1.id}") do
      # Paint names render in condensed caps, so match case-insensitively
      assert_selector "a", text: /#{@paint1.name}/i
      assert_text @brand.name
    end
  end

  test "viewing user paints collection" do
    visit user_paints_path

    assert_selector "h1", text: /my rack/i

    # Verify paint info is correctly displayed
    # Paint names render in condensed caps, so match case-insensitively
    assert_text(/Test Paint 1/i)
    assert_text(/Test Paint 2/i)
    assert_text "Test Brand"
    assert_text "Test Line"
    assert_text(/owned/i)
  end

  test "empty state is shown when no paints are found" do
    # Remove user's paints
    @user.user_paints.destroy_all

    visit user_paints_path

    # Test empty state is displayed
    assert_selector "h2", text: /start your collection/i
    assert_link "Add your first paint"
    assert_no_text @paint1.name
  end
end
