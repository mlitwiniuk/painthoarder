# frozen_string_literal: true

# Module for handling color categorization logic
module ColorCategorization
  extend ActiveSupport::Concern

  # Color categorization constants
  METALLIC_KEYWORDS = ['metallic', 'metal', 'gold', 'silver', 'bronze', 'copper', 'steel', 'chrome', 'iron'].freeze
  COLOR_CATEGORIES = ["Red", "Blue", "Green", "Yellow", "Purple", "Cyan", "Brown", "White", "Black", "Gray", "Metallic", "Other"].freeze

  # For use by the dashboard charts and other displays
  def self.categorize(paint)
    # Check for metallics based on name first (before RGB analysis)
    name = paint.name.downcase
    if METALLIC_KEYWORDS.any? { |keyword| name.include?(keyword) }
      return "Metallics"
    end
    
    # Get RGB values for analysis
    r, g, b = paint.red, paint.green, paint.blue

    # Check for neutrals first
    if r > 180 && g > 180 && b > 180
      "Whites"
    elsif r < 50 && g < 50 && b < 50
      "Blacks"
    elsif (r - g).abs < 30 && (g - b).abs < 30 && (r - b).abs < 30
      "Grays"
    # Browns: Red dominant, green moderate, blue lowest
    elsif r > g && g > b && r > 100 && g > 60 && g < 150 && b < 80 && r > b * 1.5
      "Browns"
    # For blues: Blue should be dominant and significantly higher than others
    elsif b > r && b > g && b > 100 && b > 1.5 * [r, g].max
      "Blues"
    # For reds: Red should be dominant
    elsif r > g && r > b && r > 100 && r > 1.5 * [g, b].max
      "Reds"
    # For greens: Green should be dominant
    elsif g > r && g > b && g > 100 && g > 1.5 * [r, b].max
      "Greens"
    # For yellows: Red and green high, blue low
    elsif r > 150 && g > 150 && b < 100 && r > b * 1.8 && g > b * 1.8
      "Yellows"
    # For purples: Red and blue high, green low
    elsif r > 100 && b > 100 && g < 100 && r > g * 1.5 && b > g * 1.5
      "Purples"
    # For cyans: Green and blue high, red low
    elsif g > 100 && b > 100 && r < 100 && g > r * 1.5 && b > r * 1.5
      "Cyans"
    else
      "Other"
    end
  end

  # For filtering paints by color
  def self.filter_query(query, color, model: 'paints')
    color_table = model.to_s

    case color.to_s.downcase
    when "brown"
      query.where("#{color_table}.red > #{color_table}.green AND #{color_table}.green > #{color_table}.blue AND
                  #{color_table}.red > 100 AND #{color_table}.green > 60 AND #{color_table}.green < 150 AND 
                  #{color_table}.blue < 80 AND #{color_table}.red > #{color_table}.blue * 1.5")
    when "red"
      query.where("#{color_table}.red > #{color_table}.green AND #{color_table}.red > #{color_table}.blue AND
                  #{color_table}.red > 100 AND #{color_table}.red > #{color_table}.blue * 1.5 AND 
                  #{color_table}.red > #{color_table}.green * 1.5")
    when "blue"
      query.where("#{color_table}.blue > #{color_table}.red AND #{color_table}.blue > #{color_table}.green AND
                  #{color_table}.blue > 100 AND #{color_table}.blue > #{color_table}.red * 1.5 AND 
                  #{color_table}.blue > #{color_table}.green * 1.5")
    when "green"
      query.where("#{color_table}.green > #{color_table}.red AND #{color_table}.green > #{color_table}.blue AND
                  #{color_table}.green > 100 AND #{color_table}.green > #{color_table}.red * 1.5 AND 
                  #{color_table}.green > #{color_table}.blue * 1.5")
    when "yellow"
      query.where("#{color_table}.red > 150 AND #{color_table}.green > 150 AND #{color_table}.blue < 100 AND
                  #{color_table}.red > #{color_table}.blue * 1.8 AND #{color_table}.green > #{color_table}.blue * 1.8")
    when "purple"
      query.where("#{color_table}.red > 100 AND #{color_table}.blue > 100 AND #{color_table}.green < 100 AND
                  #{color_table}.red > #{color_table}.green * 1.5 AND #{color_table}.blue > #{color_table}.green * 1.5")
    when "cyan"
      query.where("#{color_table}.green > 100 AND #{color_table}.blue > 100 AND #{color_table}.red < 100 AND
                  #{color_table}.green > #{color_table}.red * 1.5 AND #{color_table}.blue > #{color_table}.red * 1.5")
    when "white"
      query.where("#{color_table}.red > 180 AND #{color_table}.green > 180 AND #{color_table}.blue > 180")
    when "black"
      query.where("#{color_table}.red < 50 AND #{color_table}.green < 50 AND #{color_table}.blue < 50")
    when "gray"
      query.where("ABS(#{color_table}.red - #{color_table}.green) < 30 AND 
                  ABS(#{color_table}.green - #{color_table}.blue) < 30 AND 
                  ABS(#{color_table}.red - #{color_table}.blue) < 30")
    when "metallic"
      metallic_conditions = METALLIC_KEYWORDS.map { |keyword| "#{color_table}.name ILIKE '%#{keyword}%'" }.join(" OR ")
      query.where(metallic_conditions)
    else
      query
    end
  end
end
