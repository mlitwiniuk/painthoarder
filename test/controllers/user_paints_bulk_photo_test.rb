require "test_helper"

class UserPaintsBulkPhotoTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :confirmed)
    sign_in @user
    @photo = fixture_file_upload("test_paints.jpg", "image/jpeg")
  end

  test "should handle photo upload without photo" do
    post bulk_search_from_photo_user_paints_path
    assert_response :success
    assert_match "Please select a photo to analyze", response.body
  end

  test "should require photo for analysis" do
    post bulk_search_from_photo_user_paints_path, params: { photo: nil }
    assert_response :success
    assert_match "Please select a photo to analyze", response.body
  end

  test "route should exist for bulk search from photo" do
    assert_routing(
      { path: "/user_paints/bulk_search_from_photo", method: :post },
      { controller: "user_paints", action: "bulk_search_from_photo" }
    )
  end
end