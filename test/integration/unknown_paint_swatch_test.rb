require "test_helper"

class UnknownPaintSwatchTest < ActionDispatch::IntegrationTest
  test "unknown swatches render across catalog and collection pages" do
    user = create(:confirmed_user)
    paint = create(:paint, red: nil, green: nil, blue: nil)
    up = create(:user_paint, user: user, paint: paint)
    sign_in user
    [paints_path, paint_path(paint), user_paints_path, user_paint_path(up), user_root_path, color_wheel_user_paints_path].each do |path|
      get path
      follow_redirect! if response.redirect?
      assert_response :success, path
    end
    assert_includes response.body, "unknown swatches"
    assert_not_includes response.body, "&quot;name&quot;:&quot;#{paint.name}&quot;"
    get paint_path(paint)
    follow_redirect! if response.redirect?
    assert_includes response.body, "Swatch unknown"
    get similar_paint_path(paint)
    assert_response :success
  end

  test "video alternatives skip source paints and candidates without swatches" do
    user = create(:confirmed_user)
    unknown = create(:paint, red: nil, green: nil, blue: nil)
    video = create(:video, :completed, user: user)
    create(:video_paint, video: video, paint: unknown)
    sign_in user
    get alternatives_video_path(video, brand_slug: unknown.brand.slug)
    assert_response :success
  end
end
