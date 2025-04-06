# app/services/markdown_color_parser.rb
class MarkdownColorParser
  attr_reader :content

  def initialize(content)
    @content = content
  end

  def parse
    {
      brand: extract_brand_info,
      colors: extract_colors
    }
  end

  private

  def extract_brand_info
    # Extract brand name from first line
    brand_name_match = content.match(/^# (.+)/)
    brand_name = brand_name_match ? brand_name_match[1].strip : nil

    # Extract logo path from the second line
    logo_match = content.match(/!\[.+?\]\((.+?)\s*(?:".*?")?\)/)
    logo_path = logo_match ? logo_match[1] : nil

    {
      name: brand_name,
      logo_path: logo_path
    }
  end

  def extract_colors
    # Find the table in the markdown content by looking for the header line
    lines = content.lines

    # Check for both possible header formats
    header_with_code = "|Name|Code|Set|R|G|B|Hex|"
    header_without_code = "|Name|Set|R|G|B|Hex|"

    header_line_index = lines.find_index { |line|
      line.include?(header_with_code) || line.include?(header_without_code)
    }

    return [] unless header_line_index

    # Determine the table format
    has_code_column = lines[header_line_index].include?(header_with_code)

    # Get table rows (skip header and separator lines)
    color_rows = lines[(header_line_index + 2)..-1]

    # Find where the table ends (when a line doesn't start with |)
    table_end_index = color_rows.find_index { |line| !line.start_with?("|") }
    color_rows = table_end_index ? color_rows[0...table_end_index] : color_rows

    # Process each color row
    color_rows.map do |row|
      # Split the row by | and remove the first and last elements (which are empty)
      columns = row.split("|")[1..-1].map(&:strip)
      next if columns.nil? || columns.size < (has_code_column ? 7 : 6)

      if has_code_column
        name, code, set, r, g, b, hex = columns
      else
        name, set, r, g, b, hex = columns
        code = name # Use name as code if code column doesn't exist
      end

      # Extract just the hex code from the markdown
      hex_code = hex.match(/#[0-9A-F]{6}/)&.[](0) if hex

      {
        name: name,
        code: code,
        set: set,
        r: r.to_i,
        g: g.to_i,
        b: b.to_i,
        hex: hex_code
      }
    end.compact
  end
end
