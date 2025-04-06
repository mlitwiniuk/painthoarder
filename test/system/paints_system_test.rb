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
    
    assert_selector "h1", text: "Paint Catalog"
    
    # Test sort bar with pagination info is present
    assert_selector "h2.text-lg.font-semibold"
    assert_text "Sort by:"
    
    # Test paint cards are displayed
    assert_selector ".card.bg-base-100", minimum: 1
    
    # Test individual paint card elements
    within(first(".card.bg-base-100")) do
      assert_selector ".card-title"
      assert_selector ".card-body"
    end
  end
  
  test "viewing user paints collection" do
    visit user_paints_path
    
    assert_selector "h1", text: "My Paint Collection"
    
    # Verify paint info is correctly displayed
    assert_text "Test Paint 1"
    assert_text "Test Paint 2"
    assert_text "Test Brand • Test Line"
    assert_text "Owned"
  end
  
  test "empty state is shown when no paints are found" do
    # Remove user's paints
    @user.user_paints.destroy_all
    
    visit user_paints_path
    
    # Test empty state is displayed
    assert_selector ".card.bg-base-200"
    assert_text "No paints found"
  end
end
