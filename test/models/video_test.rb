require "test_helper"

class VideoTest < ActiveSupport::TestCase
  # Validations
  should validate_presence_of(:youtube_video_id)

  # Associations
  should belong_to(:user)
  should have_many(:video_paints).dependent(:destroy)

  test "validates uniqueness of youtube_video_id" do
    existing = create(:video)
    duplicate = build(:video, youtube_video_id: existing.youtube_video_id)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:youtube_video_id], "has already been taken"
  end

  test "extract_video_id from standard youtube URL" do
    assert_equal "dQw4w9WgXcQ", Video.extract_video_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
  end

  test "extract_video_id from short youtube URL" do
    assert_equal "dQw4w9WgXcQ", Video.extract_video_id("https://youtu.be/dQw4w9WgXcQ")
  end

  test "extract_video_id from embed URL" do
    assert_equal "dQw4w9WgXcQ", Video.extract_video_id("https://www.youtube.com/embed/dQw4w9WgXcQ")
  end

  test "extract_video_id from shorts URL" do
    assert_equal "dQw4w9WgXcQ", Video.extract_video_id("https://www.youtube.com/shorts/dQw4w9WgXcQ")
  end

  test "extract_video_id from URL with extra params" do
    assert_equal "dQw4w9WgXcQ", Video.extract_video_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=120s")
  end

  test "extract_video_id returns nil for invalid URL" do
    assert_nil Video.extract_video_id("https://example.com/video")
    assert_nil Video.extract_video_id("")
    assert_nil Video.extract_video_id(nil)
  end

  test "youtube_url returns correct URL" do
    video = build(:video, youtube_video_id: "abc123")
    assert_equal "https://www.youtube.com/watch?v=abc123", video.youtube_url
  end

  test "embed_url returns correct URL" do
    video = build(:video, youtube_video_id: "abc123")
    assert_equal "https://www.youtube.com/embed/abc123", video.embed_url
  end

  test "default_thumbnail_url returns correct URL" do
    video = build(:video, youtube_video_id: "abc123")
    assert_equal "https://img.youtube.com/vi/abc123/maxresdefault.jpg", video.default_thumbnail_url
  end

  test "completed scope returns only completed videos" do
    completed = create(:video, :completed)
    _pending = create(:video)
    _failed = create(:video, :failed)

    assert_includes Video.completed, completed
    assert_equal 1, Video.completed.count
  end

  test "recent scope orders by created_at desc" do
    old = create(:video, created_at: 2.days.ago)
    new_video = create(:video, created_at: 1.hour.ago)

    assert_equal [new_video, old], Video.recent.to_a
  end

  test "matched_paints_count" do
    video = create(:video, :completed)
    paint = create(:paint)
    create(:video_paint, video: video, paint: paint)
    create(:video_paint, video: video, paint: nil)

    assert_equal 1, video.matched_paints_count
  end

  test "unmatched_paints_count" do
    video = create(:video, :completed)
    paint = create(:paint)
    create(:video_paint, video: video, paint: paint)
    create(:video_paint, video: video, paint: nil)

    assert_equal 1, video.unmatched_paints_count
  end

  test "status enum works" do
    video = build(:video)
    assert video.pending?

    video.status = :processing
    assert video.processing?

    video.status = :completed
    assert video.completed?

    video.status = :failed
    assert video.failed?
  end
end
