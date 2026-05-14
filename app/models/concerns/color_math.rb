# Color-space conversions and perceptual distance metrics.
#
# Paint similarity must reflect how the eye perceives colour, not how RGB
# integers happen to differ. Raw RGB distance is perceptually non-uniform;
# CIELAB + CIEDE2000 is the industry standard for "how different do these
# two colours look".
module ColorMath
  module_function

  D65 = [0.95047, 1.0, 1.08883].freeze

  # sRGB (0-255 integers) -> CIELAB under a D65 white point.
  def rgb_to_lab(red, green, blue)
    rl, gl, bl = [red, green, blue].map do |channel|
      c = channel / 255.0
      c > 0.04045 ? (((c + 0.055) / 1.055)**2.4) : (c / 12.92)
    end

    x = (rl * 0.4124 + gl * 0.3576 + bl * 0.1805) / D65[0]
    y = (rl * 0.2126 + gl * 0.7152 + bl * 0.0722) / D65[1]
    z = (rl * 0.0193 + gl * 0.1192 + bl * 0.9505) / D65[2]

    fx, fy, fz = [x, y, z].map do |t|
      t > 0.008856 ? Math.cbrt(t) : ((7.787 * t) + (16.0 / 116.0))
    end

    [
      ((116.0 * fy) - 16.0).round(4),
      (500.0 * (fx - fy)).round(4),
      (200.0 * (fy - fz)).round(4)
    ]
  end

  # CIEDE2000 colour difference between two [L, a, b] triples.
  # Returns a non-negative ΔE; ~1.0 is a just-noticeable difference.
  def ciede2000(lab1, lab2)
    l1, a1, b1 = lab1
    l2, a2, b2 = lab2

    c1 = Math.sqrt((a1**2) + (b1**2))
    c2 = Math.sqrt((a2**2) + (b2**2))
    c_bar = (c1 + c2) / 2.0
    g = 0.5 * (1 - Math.sqrt((c_bar**7) / ((c_bar**7) + (25.0**7))))

    a1p = (1 + g) * a1
    a2p = (1 + g) * a2
    c1p = Math.sqrt((a1p**2) + (b1**2))
    c2p = Math.sqrt((a2p**2) + (b2**2))
    h1p = hue_angle(b1, a1p)
    h2p = hue_angle(b2, a2p)

    dlp = l2 - l1
    dcp = c2p - c1p

    dhp =
      if (c1p * c2p).zero?
        0.0
      elsif (h2p - h1p).abs <= 180
        h2p - h1p
      elsif (h2p - h1p) > 180
        h2p - h1p - 360
      else
        h2p - h1p + 360
      end
    dbig_hp = 2 * Math.sqrt(c1p * c2p) * Math.sin(deg2rad(dhp) / 2.0)

    lp_bar = (l1 + l2) / 2.0
    cp_bar = (c1p + c2p) / 2.0
    hp_bar =
      if (c1p * c2p).zero?
        h1p + h2p
      elsif (h1p - h2p).abs <= 180
        (h1p + h2p) / 2.0
      elsif (h1p + h2p) < 360
        (h1p + h2p + 360) / 2.0
      else
        (h1p + h2p - 360) / 2.0
      end

    t = 1 - (0.17 * Math.cos(deg2rad(hp_bar - 30))) +
      (0.24 * Math.cos(deg2rad(2 * hp_bar))) +
      (0.32 * Math.cos(deg2rad((3 * hp_bar) + 6))) -
      (0.20 * Math.cos(deg2rad((4 * hp_bar) - 63)))

    d_theta = 30 * Math.exp(-(((hp_bar - 275) / 25.0)**2))
    rc = 2 * Math.sqrt((cp_bar**7) / ((cp_bar**7) + (25.0**7)))
    sl = 1 + ((0.015 * ((lp_bar - 50)**2)) / Math.sqrt(20 + ((lp_bar - 50)**2)))
    sc = 1 + (0.045 * cp_bar)
    sh = 1 + (0.015 * cp_bar * t)
    rt = -Math.sin(deg2rad(2 * d_theta)) * rc

    Math.sqrt(
      ((dlp / sl)**2) +
      ((dcp / sc)**2) +
      ((dbig_hp / sh)**2) +
      (rt * (dcp / sc) * (dbig_hp / sh))
    )
  end

  # RGB (0-255) -> HSV. Returns [hue 0-360, saturation 0-1, value 0-1].
  def rgb_to_hsv(red, green, blue)
    r, g, b = red / 255.0, green / 255.0, blue / 255.0
    max = [r, g, b].max
    min = [r, g, b].min
    delta = max - min

    hue =
      if delta.zero?
        0.0
      elsif max == r
        60 * (((g - b) / delta) % 6)
      elsif max == g
        60 * (((b - r) / delta) + 2)
      else
        60 * (((r - g) / delta) + 4)
      end
    hue += 360 if hue < 0

    saturation = max.zero? ? 0.0 : (delta / max)
    [hue, saturation, max]
  end

  # Shortest distance between two hue angles, 0-180 degrees.
  def hue_distance(h1, h2)
    d = (h1 - h2).abs % 360
    d > 180 ? 360 - d : d
  end

  def hue_angle(b, ap)
    return 0.0 if b.zero? && ap.zero?

    angle = rad2deg(Math.atan2(b, ap))
    angle.negative? ? angle + 360 : angle
  end

  def deg2rad(degrees) = degrees * Math::PI / 180.0

  def rad2deg(radians) = radians * 180.0 / Math::PI
end
