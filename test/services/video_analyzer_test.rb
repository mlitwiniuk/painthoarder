require "test_helper"

class VideoAnalyzerTest < ActiveSupport::TestCase
  setup do
    @video = create(:video)
    @paint_data = [
      {"brand" => "Citadel", "name" => "Abaddon Black", "code" => "21-25",
       "paint_type" => "base", "hex_color" => "#231F20", "product_line_name" => "Base",
       "timestamp" => "1:30", "context" => "primer"},
      {"brand" => "Vallejo", "name" => "White", "code" => "70.951",
       "paint_type" => "model color", "hex_color" => "#FFFFFF", "product_line_name" => "Model Color",
       "timestamp" => "3:00", "context" => "highlight"}
    ]

    @mock_response = mock("response")
    @mock_response.stubs(:content).returns({"paints" => @paint_data})

    @mock_chat = mock("chat")
    @mock_chat.stubs(:with_temperature).returns(@mock_chat)
    @mock_chat.stubs(:with_instructions).returns(@mock_chat)
    @mock_chat.stubs(:with_schema).returns(@mock_chat)
    @mock_chat.stubs(:with_params).returns(@mock_chat)
    @mock_chat.stubs(:ask).returns(@mock_response)

    RubyLLM.stubs(:chat).returns(@mock_chat)
  end

  # --- Transcript path ---

  test "uses transcript when available" do
    snippet1 = stub(text: "I'm using Abaddon Black", start: 90.0, duration: 3.0)
    snippet2 = stub(text: "Now some Nuln Oil", start: 180.5, duration: 2.5)
    fetched = stub(map: nil)
    fetched.stubs(:map).returns(["[1:30] I'm using Abaddon Black", "[3:00] Now some Nuln Oil"])

    mock_api = mock("transcript_api")
    mock_api.expects(:fetch).with(@video.youtube_video_id, languages: ["en"]).returns(fetched)
    YoutubeRb::Transcript::YouTubeTranscriptApi.stubs(:new).returns(mock_api)

    # Verify transcript text (not Raw content) is sent to chat
    @mock_chat.expects(:ask).with(is_a(String)).returns(@mock_response)

    analyzer = VideoAnalyzer.new(@video)
    results = analyzer.analyze

    assert_equal 2, results.length
    assert_equal "Citadel", results[0][:brand]
    assert_equal "Abaddon Black", results[0][:name]
  end

  test "transcript formats timestamps correctly" do
    snippet1 = stub(text: "First paint", start: 30, duration: 2.0)
    snippet2 = stub(text: "Second paint", start: 125, duration: 3.0)

    mock_api = mock("transcript_api")
    fetched_transcript = [snippet1, snippet2]
    mock_api.stubs(:fetch).returns(fetched_transcript)
    YoutubeRb::Transcript::YouTubeTranscriptApi.stubs(:new).returns(mock_api)

    @mock_chat.expects(:ask).with { |text|
      text.include?("[0:30] First paint") && text.include?("[2:05] Second paint")
    }.returns(@mock_response)

    VideoAnalyzer.new(@video).analyze
  end

  # --- Video fallback path ---

  test "falls back to video when transcript unavailable" do
    mock_api = mock("transcript_api")
    mock_api.stubs(:fetch).raises(StandardError.new("No transcript"))
    YoutubeRb::Transcript::YouTubeTranscriptApi.stubs(:new).returns(mock_api)

    # Verify Raw content (not plain text) is sent
    @mock_chat.expects(:ask).with(is_a(RubyLLM::Content::Raw)).returns(@mock_response)
    # Verify low-res param is set
    @mock_chat.expects(:with_params).with(generationConfig: {mediaResolution: "MEDIA_RESOLUTION_LOW"}).returns(@mock_chat)

    analyzer = VideoAnalyzer.new(@video)
    results = analyzer.analyze

    assert_equal 2, results.length
    assert_equal "Citadel", results[0][:brand]
  end

  # --- Shared response parsing ---

  test "analyze returns array of paint hashes with all fields" do
    mock_api = mock("transcript_api")
    mock_api.stubs(:fetch).raises(StandardError.new("No transcript"))
    YoutubeRb::Transcript::YouTubeTranscriptApi.stubs(:new).returns(mock_api)

    analyzer = VideoAnalyzer.new(@video)
    results = analyzer.analyze

    assert_equal 2, results.length
    assert_equal "Citadel", results[0][:brand]
    assert_equal "Abaddon Black", results[0][:name]
    assert_equal "21-25", results[0][:code]
    assert_equal "base", results[0][:paint_type]
    assert_equal "#231F20", results[0][:hex_color]
    assert_equal "Base", results[0][:product_line_name]
    assert_equal "1:30", results[0][:timestamp]
    assert_equal "primer", results[0][:context]
    assert_equal "Citadel Abaddon Black 21-25", results[0][:search_string]
  end

  test "analyze returns empty array when no paints found" do
    mock_api = mock("transcript_api")
    mock_api.stubs(:fetch).raises(StandardError.new("No transcript"))
    YoutubeRb::Transcript::YouTubeTranscriptApi.stubs(:new).returns(mock_api)

    @mock_response.stubs(:content).returns({"paints" => []})

    analyzer = VideoAnalyzer.new(@video)
    results = analyzer.analyze

    assert_equal [], results
  end

  test "analyze handles nil content gracefully" do
    mock_api = mock("transcript_api")
    mock_api.stubs(:fetch).raises(StandardError.new("No transcript"))
    YoutubeRb::Transcript::YouTubeTranscriptApi.stubs(:new).returns(mock_api)

    @mock_response.stubs(:content).returns(nil)

    analyzer = VideoAnalyzer.new(@video)
    results = analyzer.analyze

    assert_equal [], results
  end

  # --- Error handling ---

  test "analyze raises AnalysisError on RubyLLM error" do
    mock_api = mock("transcript_api")
    mock_api.stubs(:fetch).raises(StandardError.new("No transcript"))
    YoutubeRb::Transcript::YouTubeTranscriptApi.stubs(:new).returns(mock_api)

    @mock_chat.stubs(:ask).raises(RubyLLM::Error.new(nil, "API error"))

    analyzer = VideoAnalyzer.new(@video)
    assert_raises(VideoAnalyzer::AnalysisError) { analyzer.analyze }
  end

  test "PaintListSchema generates valid JSON schema" do
    schema = VideoAnalyzer::PaintListSchema.new.to_json_schema
    assert schema[:schema][:properties].key?(:paints)
  end
end
