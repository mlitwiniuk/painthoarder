require "test_helper"

class VideoPaintsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create(:user, :confirmed)
    @other_user = create(:user, :confirmed)
    @video = create(:video, :completed, user: @owner)
    @paint = create(:paint)
    @other_paint = create(:paint)
    @video_paint = create(:video_paint, :matched, video: @video, paint: @paint)
    @unmatched_video_paint = create(:video_paint, :unmatched, video: @video)
  end

  # Edit
  test "owner can edit video paint" do
    sign_in @owner
    get edit_video_video_paint_url(@video, @video_paint)
    assert_response :success
    assert_includes response.body, "Search catalog paints"
  end

  test "non-owner is redirected from edit" do
    sign_in @other_user
    get edit_video_video_paint_url(@video, @video_paint)
    assert_redirected_to video_path(@video)
  end

  test "unauthenticated user is redirected from edit" do
    get edit_video_video_paint_url(@video, @video_paint)
    assert_redirected_to new_user_session_path
  end

  # Update — re-link
  test "owner can update paint_id to re-link" do
    sign_in @owner
    patch video_video_paint_url(@video, @video_paint), params: { video_paint: { paint_id: @other_paint.id } }

    @video_paint.reload
    assert_equal @other_paint.id, @video_paint.paint_id
  end

  test "owner can update unmatched paint to link" do
    sign_in @owner
    patch video_video_paint_url(@video, @unmatched_video_paint), params: { video_paint: { paint_id: @paint.id } }

    @unmatched_video_paint.reload
    assert_equal @paint.id, @unmatched_video_paint.paint_id
  end

  # Update — clear
  test "owner can clear paint_id to unlink" do
    sign_in @owner
    patch video_video_paint_url(@video, @video_paint), params: { video_paint: { paint_id: "" } }

    @video_paint.reload
    assert_nil @video_paint.paint_id
  end

  # Update — authorization
  test "non-owner cannot update video paint" do
    sign_in @other_user
    patch video_video_paint_url(@video, @video_paint), params: { video_paint: { paint_id: @other_paint.id } }
    assert_redirected_to video_path(@video)

    @video_paint.reload
    assert_equal @paint.id, @video_paint.paint_id
  end

  test "unauthenticated user cannot update video paint" do
    patch video_video_paint_url(@video, @video_paint), params: { video_paint: { paint_id: @other_paint.id } }
    assert_redirected_to new_user_session_path

    @video_paint.reload
    assert_equal @paint.id, @video_paint.paint_id
  end

  # Turbo stream response
  test "update responds with turbo stream" do
    sign_in @owner
    patch video_video_paint_url(@video, @video_paint),
      params: { video_paint: { paint_id: @other_paint.id } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end
end
