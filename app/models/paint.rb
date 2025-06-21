# == Schema Information
#
# Table name: paints
#
#  id              :integer          not null, primary key
#  blue            :integer
#  code            :string
#  green           :integer
#  hex_color       :string
#  name            :string
#  red             :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_line_id :integer          not null
#
# Indexes
#
#  index_paints_on_product_line_id  (product_line_id)
#
# Foreign Keys
#
#  product_line_id  (product_line_id => product_lines.id)
#
class Paint < ApplicationRecord
  ## CONCERNS
  include SqliteSearch
  search_scope(:name, :code, :brand_name, :product_line_name, :name_code_normalized, includes: [:brand, :product_line])

  ## ATTRIBUTES
  has_one_attached :image

  ## ASSOCIATIONS
  belongs_to :product_line
  has_one :brand, through: :product_line
  has_many :user_paints, dependent: :destroy

  ## VALIDATIONS
  validates :name, :code, presence: true
  validates :red, :green, :blue, presence: true,
    numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 255}

  ## BEFORE & AFTER
  before_save :set_hex_color

  def brand_name
    brand.name
  end

  def product_line_name
    product_line.name
  end

  def name_code_normalized
    "#{name} #{code}".tr("^A-Za-z0-9\s", "")
  end

  def color_category
    # Convert RGB to HSV for better color classification
    r, g, b = red / 255.0, green / 255.0, blue / 255.0
    max_val = [r, g, b].max
    min_val = [r, g, b].min
    delta = max_val - min_val

    # Calculate saturation and value (brightness)
    saturation = max_val == 0 ? 0 : delta / max_val
    value = max_val

    # Calculate hue
    if delta == 0
      hue = 0
    elsif max_val == r
      hue = 60 * (((g - b) / delta) % 6)
    elsif max_val == g
      hue = 60 * (((b - r) / delta) + 2)
    else
      hue = 60 * (((r - g) / delta) + 4)
    end

    # Normalize hue to 0-360
    hue = hue < 0 ? hue + 360 : hue

    # Special cases for achromatic colors
    if saturation < 0.1
      return 'Black' if value < 0.2
      return 'Dark Gray' if value < 0.4
      return 'Gray' if value < 0.6
      return 'Light Gray' if value < 0.8
      return 'White'
    end

    # Low saturation colors (muted/pastel)
    if saturation < 0.3
      return 'Beige' if hue >= 30 && hue < 60 && value > 0.7
      return 'Cream' if hue >= 45 && hue < 75 && value > 0.8
      return 'Ivory' if hue >= 50 && hue < 70 && value > 0.9
    end

    # High saturation, low value (dark colors)
    if value < 0.3
      return 'Maroon' if hue >= 345 || hue < 15
      return 'Dark Red' if hue >= 345 || hue < 15
      return 'Dark Orange' if hue >= 15 && hue < 45
      return 'Dark Yellow' if hue >= 45 && hue < 75
      return 'Dark Green' if hue >= 75 && hue < 165
      return 'Dark Cyan' if hue >= 165 && hue < 195
      return 'Dark Blue' if hue >= 195 && hue < 255
      return 'Dark Purple' if hue >= 255 && hue < 285
      return 'Dark Magenta' if hue >= 285 && hue < 345
    end

    # Color classification by hue ranges
    case hue
    when 0..15, 345..360
      return 'Pink' if saturation < 0.7 && value > 0.7
      return 'Rose' if saturation < 0.5 && value > 0.8
      return 'Red'
    when 15..45
      return 'Coral' if saturation < 0.7 && value > 0.7
      return 'Peach' if saturation < 0.5 && value > 0.8
      return 'Orange'
    when 45..75
      return 'Gold' if saturation > 0.7 && value > 0.7
      return 'Khaki' if saturation < 0.5 && value > 0.6
      return 'Yellow'
    when 75..105
      return 'Lime' if saturation > 0.7 && value > 0.7
      return 'Olive' if saturation > 0.3 && value < 0.6
      return 'Yellow Green'
    when 105..135
      return 'Forest Green' if saturation > 0.5 && value < 0.6
      return 'Mint' if saturation < 0.5 && value > 0.8
      return 'Green'
    when 135..165
      return 'Teal' if saturation > 0.5
      return 'Sage' if saturation < 0.4 && value > 0.6
      return 'Green'
    when 165..195
      return 'Turquoise' if saturation > 0.5 && value > 0.6
      return 'Aqua' if saturation > 0.7 && value > 0.7
      return 'Cyan'
    when 195..225
      return 'Sky Blue' if saturation < 0.7 && value > 0.7
      return 'Navy' if saturation > 0.5 && value < 0.5
      return 'Blue'
    when 225..255
      return 'Royal Blue' if saturation > 0.7 && value > 0.5
      return 'Slate Blue' if saturation < 0.6 && value > 0.4
      return 'Blue'
    when 255..285
      return 'Indigo' if saturation > 0.5 && value < 0.6
      return 'Lavender' if saturation < 0.5 && value > 0.8
      return 'Purple'
    when 285..315
      return 'Violet' if saturation > 0.6 && value > 0.6
      return 'Plum' if saturation < 0.6 && value > 0.5
      return 'Purple'
    when 315..345
      return 'Magenta' if saturation > 0.7
      return 'Mauve' if saturation < 0.5 && value > 0.6
      return 'Pink'
    else
      return nil
    end
  end

  ## RANSACK CONFIG
  # Define which attributes can be used for searching
  def self.ransackable_attributes(auth_object = nil)
    ["blue", "code", "created_at", "green", "hex_color", "id", "name", "product_line_id", "red", "updated_at"]
  end

  # Define which associations can be used for searching
  def self.ransackable_associations(auth_object = nil)
    ["brand", "product_line", "user_paints"]
  end

  # Make custom sort work for associations
  def self.ransortable_attributes(auth_object = nil)
    ransackable_attributes(auth_object) + ["product_line_brand_name"]
  end

  private

  ## Callbacks
  def set_hex_color
    self.hex_color = "##{red.to_s(16).rjust(2, "0")}#{green.to_s(16).rjust(2, "0")}#{blue.to_s(16).rjust(2, "0")}"
  end
end
