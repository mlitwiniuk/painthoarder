module ApplicationHelper
  # Convert RGB values to HSL (Hue, Saturation, Lightness)
  # @param r [Integer] Red value (0-255)
  # @param g [Integer] Green value (0-255)
  # @param b [Integer] Blue value (0-255)
  # @return [Array] Array containing [h, s, l] values where h is in degrees (0-360) and s, l are percentages (0-100)
  def rgb_to_hsl(r, g, b)
    r /= 255.0
    g /= 255.0
    b /= 255.0

    max = [r, g, b].max
    min = [r, g, b].min

    h = s = l = (max + min) / 2.0

    if max == min
      h = s = 0 # achromatic
    else
      d = max - min
      s = (l > 0.5) ? d / (2.0 - max - min) : d / (max + min)

      case max
      when r
        h = (g - b) / d + ((g < b) ? 6 : 0)
      when g
        h = (b - r) / d + 2
      when b
        h = (r - g) / d + 4
      end

      h /= 6.0
    end

    # Convert to degrees and percentages
    h = (h * 360).round
    s = (s * 100).round
    l = (l * 100).round

    [h, s, l]
  end

  include Pagy::Frontend
  def container_class
    if controller_name == "pages" && action_name == "welcome"
      "container-full"
    else
      "container"
    end
  end

  def gravatar_for(user, options = {size: 200})
    hash = Digest::MD5.hexdigest(user.email.downcase)
    size = options[:size]
    gravatar_url = "https://robohash.org/#{hash}?gravatar=hashed&size=#{size}x#{size}&bgset=bg1"
    image_tag(gravatar_url, alt: user.username, class: "img-circle")
  end

  def user_paint_status_icon(status)
    case status
    when "owned"
      "✅"
    when "wishlist"
      "❤️"
    when "avoid"
      "❌"
    end
  end
end
