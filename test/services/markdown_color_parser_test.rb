# test/services/markdown_color_parser_test.rb
require 'test_helper'

class MarkdownColorParserTest < ActiveSupport::TestCase
  setup do
    @sample_with_code = <<~MARKDOWN
      # Foundry
      ![Foundry](../logos/Foundry.png "Foundry")

      |Name|Code|Set|R|G|B|Hex|
      |---|---|---|---|---|---|---|
      |African Flesh|126B|Foundry Paint System|115|72|79|![#73484F](https://placehold.co/15x15/73484F/73484F.png) `#73484F`|
      |African Flesh Light|126C|Foundry Paint System|143|79|80|![#8F4F50](https://placehold.co/15x15/8F4F50/8F4F50.png) `#8F4F50`|
      <p align="center">Made available by <a href="https://example.com/">Example</a></p>
    MARKDOWN

    @sample_without_code = <<~MARKDOWN
      # AltBrand
      ![AltBrand](../logos/AltBrand.png "AltBrand")

      |Name|Set|R|G|B|Hex|
      |---|---|---|---|---|---|
      |Deep Blue|AltBrand System|0|62|114|![#003E72](https://placehold.co/15x15/003E72/003E72.png) `#003E72`|
      |Sky Blue|AltBrand System|74|138|199|![#4A8AC7](https://placehold.co/15x15/4A8AC7/4A8AC7.png) `#4A8AC7`|
      <p align="center">Made available by <a href="https://example.com/">Example</a></p>
    MARKDOWN

    @parser_with_code = MarkdownColorParser.new(@sample_with_code)
    @parser_without_code = MarkdownColorParser.new(@sample_without_code)
  end

  test "extracts brand information with code" do
    result = @parser_with_code.parse

    assert_equal "Foundry", result[:brand][:name]
    assert_equal "../logos/Foundry.png", result[:brand][:logo_path]
  end

  test "extracts brand information without code" do
    result = @parser_without_code.parse

    assert_equal "AltBrand", result[:brand][:name]
    assert_equal "../logos/AltBrand.png", result[:brand][:logo_path]
  end

  test "extracts color data with code column" do
    colors = @parser_with_code.parse[:colors]

    assert_equal 2, colors.size

    assert_equal "African Flesh", colors[0][:name]
    assert_equal "126B", colors[0][:code]
    assert_equal "Foundry Paint System", colors[0][:set]
    assert_equal 115, colors[0][:r]
    assert_equal 72, colors[0][:g]
    assert_equal 79, colors[0][:b]
    assert_equal "#73484F", colors[0][:hex]

    assert_equal "African Flesh Light", colors[1][:name]
    assert_equal "#8F4F50", colors[1][:hex]
  end

  test "extracts color data without code column" do
    colors = @parser_without_code.parse[:colors]

    assert_equal 2, colors.size

    assert_equal "Deep Blue", colors[0][:name]
    assert_equal "Deep Blue", colors[0][:code] # Code should be set to name
    assert_equal "AltBrand System", colors[0][:set]
    assert_equal 0, colors[0][:r]
    assert_equal 62, colors[0][:g]
    assert_equal 114, colors[0][:b]
    assert_equal "#003E72", colors[0][:hex]

    assert_equal "Sky Blue", colors[1][:name]
    assert_equal "Sky Blue", colors[1][:code] # Code should be set to name
    assert_equal "#4A8AC7", colors[1][:hex]
  end
end
