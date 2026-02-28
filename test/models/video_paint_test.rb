require "test_helper"

class VideoPaintTest < ActiveSupport::TestCase
  # Validations
  should validate_presence_of(:paint_name)

  # Associations
  should belong_to(:video)
  should belong_to(:paint).optional

  test "matched? returns true when paint is present" do
    paint = create(:paint)
    video_paint = build(:video_paint, paint: paint)
    assert video_paint.matched?
  end

  test "matched? returns false when paint is nil" do
    video_paint = build(:video_paint, paint: nil)
    assert_not video_paint.matched?
  end

  test "matched scope returns video_paints with paint" do
    video = create(:video, :completed)
    paint = create(:paint)
    matched = create(:video_paint, video: video, paint: paint)
    _unmatched = create(:video_paint, video: video, paint: nil)

    assert_includes VideoPaint.matched, matched
    assert_equal 1, VideoPaint.matched.count
  end

  test "unmatched scope returns video_paints without paint" do
    video = create(:video, :completed)
    paint = create(:paint)
    _matched = create(:video_paint, video: video, paint: paint)
    unmatched = create(:video_paint, video: video, paint: nil)

    assert_includes VideoPaint.unmatched, unmatched
    assert_equal 1, VideoPaint.unmatched.count
  end
end
