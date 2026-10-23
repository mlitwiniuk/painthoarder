require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :confirmed)
    @brand = create(:brand, name: "Citadel")
    @line = create(:product_line, brand: @brand, name: "Base")
    @owned_paint = create(:paint, name: "Abaddon Black", product_line: @line, hex_color: "#1C1A1A")
    @wanted_paint = create(:paint, name: "Mephiston Red", product_line: @line, hex_color: "#9A1115")
    @owned = create(:user_paint, user: @user, paint: @owned_paint)
    @wanted = create(:user_paint, :wishlist, user: @user, paint: @wanted_paint)
    sign_in @user
  end

  test "renders greeting, counts, shopping list and recently added" do
    get user_root_path

    assert_response :success
    assert_select "h1", text: /, #{@user.name}\z/
    assert_select "p.eyebrow", text: /1 owned · 1 wanted · 0 projects/
    assert_select "#shopping-list-title", text: "Shopping list"
    assert_select "##{ActionView::RecordIdentifier.dom_id(@wanted)}", text: /Mephiston Red/
    assert_select "#recent-title", text: "Recently added"
    assert_select "a[href=?]", user_paint_path(@owned), text: /Abaddon Black/
  end

  test "shows empty states for a new user" do
    @user.user_paints.destroy_all
    get user_root_path

    assert_response :success
    assert_select "span", text: "Nothing on the wishlist"
    assert_select "span", text: "Your rack is empty"
  end

  test "shows latest project and video cards with real counts" do
    project = create(:project, user: @user, title: "WHQ: Dwarf Warriors")
    video = create(:video, :completed, user: @user, title: "Painting dwarves")
    create(:video_paint, video: video, paint: @owned_paint)
    create(:video_paint, video: video, paint: @wanted_paint)

    get user_root_path

    assert_select "a[href=?]", project_path(project), text: "WHQ: Dwarf Warriors"
    assert_select "a[href=?]", new_project_project_update_path(project)
    assert_select "span", text: "1 of 2 on your rack"
    assert_select "a[href=?]", video_path(video), text: /See the 1 you're missing/
  end

  test "rack check frame reports the status of matching paints" do
    get user_root_path(check: "abaddon"), headers: {"Turbo-Frame" => "rack-check"}

    assert_response :success
    assert_select "turbo-frame#rack-check" do
      assert_select "b", text: "Abaddon Black"
      assert_select ".tag-owned", text: /Owned/
    end
    assert_match "Put it back", response.body
    assert_no_match "Shopping list", response.body
  end

  test "Got it marks a wanted paint as owned" do
    patch user_paint_path(@wanted), params: {user_paint: {status: "owned"}}

    assert @wanted.reload.owned?
  end
end
