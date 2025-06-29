require "test_helper"

class PaintPhotoAnalyzerTest < ActiveSupport::TestCase
  setup do
    @mock_photo = mock_photo_attachment
  end

  test "initializes with default config when no config file exists" do
    analyzer = PaintPhotoAnalyzer.new(@mock_photo)
    assert_not_nil analyzer
  end

  test "parses paint list correctly from JSON response" do
    analyzer = PaintPhotoAnalyzer.new(@mock_photo)
    json_response = '[{"brand": "Citadel", "name": "Abaddon Black", "code": "21-25"}]'
    result = analyzer.send(:parse_paint_list, json_response)
    
    assert_equal 1, result.length
    assert_equal "Citadel", result[0][:brand]
    assert_equal "Abaddon Black", result[0][:name]
    assert_equal "21-25", result[0][:code]
    assert_equal "Citadel Abaddon Black 21-25", result[0][:search_string]
  end

  test "handles empty response gracefully" do
    analyzer = PaintPhotoAnalyzer.new(@mock_photo)
    result = analyzer.send(:parse_paint_list, "")
    assert_equal [], result
  end

  test "handles invalid JSON gracefully" do
    analyzer = PaintPhotoAnalyzer.new(@mock_photo)
    result = analyzer.send(:parse_paint_list, "invalid json")
    assert_equal [], result
  end

  test "extracts JSON from markdown code blocks" do
    analyzer = PaintPhotoAnalyzer.new(@mock_photo)
    markdown_response = "Here are the paints:\n```json\n[{\"brand\": \"Vallejo\", \"name\": \"White\", \"code\": \"70.951\"}]\n```"
    result = analyzer.send(:parse_paint_list, markdown_response)
    
    assert_equal 1, result.length
    assert_equal "Vallejo", result[0][:brand]
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

  test "raises error for unsupported provider" do
    analyzer = PaintPhotoAnalyzer.new(@mock_photo)
    analyzer.instance_variable_set(:@llm_config, { provider: "unsupported" })
    
    assert_raises(PaintPhotoAnalyzer::AnalysisError) do
      analyzer.analyze
    end
  end

  private

  def mock_photo_attachment
    # Create a mock uploaded file object
    file = StringIO.new("fake image data")
    
    # Add the required methods
    def file.content_type
      "image/jpeg"
    end
    
    def file.rewind
      seek(0)
    end
    
    file
  end
end