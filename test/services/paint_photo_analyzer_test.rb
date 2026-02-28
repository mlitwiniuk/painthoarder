require "test_helper"

class PaintPhotoAnalyzerTest < ActiveSupport::TestCase
  setup do
    @mock_photo = mock_photo_attachment
  end

  test "initializes with a photo" do
    analyzer = PaintPhotoAnalyzer.new(@mock_photo)
    assert_not_nil analyzer
  end

  test "builds search string correctly" do
    analyzer = PaintPhotoAnalyzer.new(@mock_photo)
    paint = { "brand" => "Army Painter", "name" => "Pure Red", "code" => "WP1104" }
    search_string = analyzer.send(:build_search_string, paint)

    assert_equal "Army Painter Pure Red WP1104", search_string
  end

  test "builds search string with missing fields" do
    analyzer = PaintPhotoAnalyzer.new(@mock_photo)
    paint = { "brand" => "Citadel", "name" => "Blood Red", "code" => nil }
    search_string = analyzer.send(:build_search_string, paint)

    assert_equal "Citadel Blood Red", search_string
  end

  test "analyze calls RubyLLM with tool and returns structured paints" do
    analyzer = PaintPhotoAnalyzer.new(@mock_photo)

    paints_data = [{ "brand" => "Citadel", "name" => "Abaddon Black", "code" => "21-25" }]
    mock_tool = PaintPhotoAnalyzer::PaintIdentifier.new
    mock_tool.instance_variable_set(:@identified_paints, paints_data)

    PaintPhotoAnalyzer::PaintIdentifier.stubs(:new).returns(mock_tool)

    fake_chat = stub("chat")
    fake_chat.stubs(:with_temperature).returns(fake_chat)
    fake_chat.stubs(:with_instructions).returns(fake_chat)
    fake_chat.stubs(:with_tool).returns(fake_chat)
    fake_chat.stubs(:ask).returns(stub(content: "Done"))

    RubyLLM.stubs(:chat).returns(fake_chat)

    result = analyzer.analyze
    assert_equal 1, result.length
    assert_equal "Citadel", result[0][:brand]
    assert_equal "Abaddon Black", result[0][:name]
    assert_equal "21-25", result[0][:code]
    assert_equal "Citadel Abaddon Black 21-25", result[0][:search_string]
  end

  test "analyze returns empty array when tool is not called" do
    analyzer = PaintPhotoAnalyzer.new(@mock_photo)

    mock_tool = PaintPhotoAnalyzer::PaintIdentifier.new
    PaintPhotoAnalyzer::PaintIdentifier.stubs(:new).returns(mock_tool)

    fake_chat = stub("chat")
    fake_chat.stubs(:with_temperature).returns(fake_chat)
    fake_chat.stubs(:with_instructions).returns(fake_chat)
    fake_chat.stubs(:with_tool).returns(fake_chat)
    fake_chat.stubs(:ask).returns(stub(content: "No paints found"))

    RubyLLM.stubs(:chat).returns(fake_chat)

    result = analyzer.analyze
    assert_equal [], result
  end

  test "analyze wraps LLM errors in AnalysisError" do
    analyzer = PaintPhotoAnalyzer.new(@mock_photo)

    fake_chat = stub("chat")
    fake_chat.stubs(:with_temperature).returns(fake_chat)
    fake_chat.stubs(:with_instructions).returns(fake_chat)
    fake_chat.stubs(:with_tool).returns(fake_chat)
    fake_chat.stubs(:ask).raises(RubyLLM::Error.new(nil, "API connection failed"))

    RubyLLM.stubs(:chat).returns(fake_chat)

    error = assert_raises(PaintPhotoAnalyzer::AnalysisError) do
      analyzer.analyze
    end
    assert_match(/LLM analysis failed/, error.message)
  end

  test "PaintIdentifier tool stores paints on execute" do
    tool = PaintPhotoAnalyzer::PaintIdentifier.new
    paints = [{ "brand" => "Vallejo", "name" => "White", "code" => "70.951" }]

    assert_nil tool.identified_paints
    tool.execute(paints: paints)
    assert_equal paints, tool.identified_paints
  end

  private

  def mock_photo_attachment
    file = StringIO.new("fake image data")

    def file.content_type
      "image/jpeg"
    end

    def file.rewind
      seek(0)
    end

    file
  end
end
