require "test_helper"

class VideoAnalysisJobTest < ActiveSupport::TestCase
  setup do
    @video = create(:video, status: :pending)
    @paint = create(:paint, name: "Abaddon Black", code: "21-25")
  end

  test "sets video to processing then completed on success" do
    analyzer = mock("analyzer")
    analyzer.stubs(:analyze).returns([
      {brand: "Citadel", name: "Abaddon Black", code: "21-25",
       paint_type: "base", hex_color: "#231F20", product_line_name: "Base",
       timestamp: "1:30", context: "base coat",
       search_string: "Citadel Abaddon Black 21-25"}
    ])

    VideoAnalyzer.stubs(:new).returns(analyzer)
    Turbo::StreamsChannel.stubs(:broadcast_replace_to)

    VideoAnalysisJob.perform_now(@video.id)

    @video.reload
    assert @video.completed?
    assert_not_nil @video.processed_at
    assert_equal 1, @video.video_paints.count
  end

  test "creates video_paints with matched paint" do
    analyzer = mock("analyzer")
    analyzer.stubs(:analyze).returns([
      {brand: "Citadel", name: "Abaddon Black", code: "21-25",
       paint_type: "base", hex_color: "#231F20", product_line_name: "Base",
       timestamp: "1:30", context: "base coat",
       search_string: "Citadel Abaddon Black 21-25"}
    ])

    VideoAnalyzer.stubs(:new).returns(analyzer)
    Turbo::StreamsChannel.stubs(:broadcast_replace_to)

    # Stub Paint.full_search to return our paint
    Paint.stubs(:full_search).with("Citadel Abaddon Black 21-25").returns(Paint.where(id: @paint.id))

    VideoAnalysisJob.perform_now(@video.id)

    video_paint = @video.video_paints.first
    assert_equal @paint, video_paint.paint
    assert_equal "Citadel", video_paint.brand_name
    assert_equal "Abaddon Black", video_paint.paint_name
    assert_equal "21-25", video_paint.paint_code
    assert_equal "base", video_paint.paint_type
    assert_equal @paint.hex_color, video_paint.hex_color
    assert_equal @paint.product_line.name, video_paint.product_line_name
    assert_equal "1:30", video_paint.timestamp
    assert_equal "base coat", video_paint.context
  end

  test "creates unmatched video_paint with estimated hex_color" do
    analyzer = mock("analyzer")
    analyzer.stubs(:analyze).returns([
      {brand: "Unknown", name: "Mystery Paint", code: "",
       paint_type: "layer", hex_color: "#FF5500", product_line_name: "Special Range",
       timestamp: "5:00", context: "highlight",
       search_string: "Unknown Mystery Paint"}
    ])

    VideoAnalyzer.stubs(:new).returns(analyzer)
    Turbo::StreamsChannel.stubs(:broadcast_replace_to)
    Paint.stubs(:full_search).returns(Paint.none)

    VideoAnalysisJob.perform_now(@video.id)

    video_paint = @video.video_paints.first
    assert_nil video_paint.paint
    assert_equal "Unknown", video_paint.brand_name
    assert_equal "Mystery Paint", video_paint.paint_name
    assert_equal "#FF5500", video_paint.hex_color
    assert_equal "Special Range", video_paint.product_line_name
  end

  test "sets video to failed on AnalysisError" do
    analyzer = mock("analyzer")
    analyzer.stubs(:analyze).raises(VideoAnalyzer::AnalysisError.new("timeout"))

    VideoAnalyzer.stubs(:new).returns(analyzer)
    Turbo::StreamsChannel.stubs(:broadcast_replace_to)

    # retry_on catches AnalysisError, so perform_now won't raise
    # but the video should be marked as failed
    begin
      VideoAnalysisJob.perform_now(@video.id)
    rescue VideoAnalyzer::AnalysisError
      # May or may not re-raise depending on retry count
    end

    @video.reload
    assert @video.failed?
    assert_equal "timeout", @video.error_message
  end

  test "sets video to failed on unexpected error" do
    analyzer = mock("analyzer")
    analyzer.stubs(:analyze).raises(StandardError.new("unexpected"))

    VideoAnalyzer.stubs(:new).returns(analyzer)
    Turbo::StreamsChannel.stubs(:broadcast_replace_to)

    # Should not re-raise unexpected errors
    VideoAnalysisJob.perform_now(@video.id)

    @video.reload
    assert @video.failed?
    assert_includes @video.error_message, "unexpected"
  end

  test "skips already completed video" do
    @video.update!(status: :completed)

    VideoAnalyzer.expects(:new).never
    Turbo::StreamsChannel.stubs(:broadcast_replace_to)

    VideoAnalysisJob.perform_now(@video.id)
  end

  test "broadcasts turbo stream on status change" do
    analyzer = mock("analyzer")
    analyzer.stubs(:analyze).returns([])

    VideoAnalyzer.stubs(:new).returns(analyzer)

    Turbo::StreamsChannel.expects(:broadcast_replace_to).at_least(2)

    VideoAnalysisJob.perform_now(@video.id)
  end
end
