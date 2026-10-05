require "test_helper"

class LlmHttpContractTest < ActiveSupport::TestCase
  setup do
    @anthropic_key = RubyLLM.config.anthropic_api_key
    @gemini_key = RubyLLM.config.gemini_api_key
    RubyLLM.configure do |config|
      config.anthropic_api_key = "test-anthropic-key"
      config.gemini_api_key = "test-gemini-key"
    end
  end

  teardown do
    RubyLLM.configure do |config|
      config.anthropic_api_key = @anthropic_key
      config.gemini_api_key = @gemini_key
    end
  end

  test "photo analysis executes the provider tool without a second completion" do
    paints = [{"brand" => "Citadel", "name" => "Abaddon Black", "code" => "21-25"}]
    request = stub_request(:post, "https://api.anthropic.com/v1/messages")
      .with do |req|
        body = JSON.parse(req.body)
        body.fetch("tools").first.fetch("input_schema").fetch("properties").key?("paints") &&
          body.fetch("messages").first.fetch("content").any? { |part| part["type"] == "image" }
      end
      .to_return(status: 200, headers: {"Content-Type" => "application/json"}, body: {
        id: "msg_test", type: "message", role: "assistant", model: "claude-haiku-4-5",
        content: [{type: "tool_use", id: "tool_test", name: PaintPhotoAnalyzer::PaintIdentifier.new.name,
                   input: {paints: paints}}],
        stop_reason: "tool_use", usage: {input_tokens: 10, output_tokens: 10}
      }.to_json)

    photo = Rack::Test::UploadedFile.new(file_fixture("1px.png"), "image/png")
    result = PaintPhotoAnalyzer.new(photo).analyze

    assert_equal "Citadel Abaddon Black 21-25", result.first.fetch(:search_string)
    assert_requested request, times: 1
  end

  test "video fallback sends Gemini video content and parses structured JSON" do
    video = create(:video)
    api = mock("transcript API")
    api.stubs(:fetch).raises(StandardError, "Transcript unavailable")
    YoutubeRb::Transcript::YouTubeTranscriptApi.stubs(:new).returns(api)
    paints = [{brand: "Vallejo", name: "White", code: "70.951"}]
    request = stub_request(:post, %r{https://generativelanguage.googleapis.com/.*/models/gemini-2\.5-flash:generateContent})
      .with do |req|
        body = JSON.parse(req.body)
        parts = body.fetch("contents").last.fetch("parts")
        parts.any? { |part| part.dig("fileData", "fileUri") == video.youtube_url } &&
          body.dig("generationConfig", "mediaResolution") == "MEDIA_RESOLUTION_LOW"
      end
      .to_return(status: 200, headers: {"Content-Type" => "application/json"}, body: {
        candidates: [{content: {role: "model", parts: [{text: {paints: paints}.to_json}]}, finishReason: "STOP"}],
        usageMetadata: {promptTokenCount: 10, candidatesTokenCount: 10}
      }.to_json)

    result = VideoAnalyzer.new(video).analyze

    assert_equal "Vallejo White 70.951", result.first.fetch(:search_string)
    assert_requested request, times: 1
  end
end
