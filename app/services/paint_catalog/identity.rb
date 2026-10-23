module PaintCatalog
  module Identity
    FIELDS = %w[name sku code range url hex status].freeze
    FAMILIES = {
      "monument" => {
        "Monument Pro Acrylic Paints" => "pro_acryl",
        "Monument Pro Signature Series" => "signature",
        "Pro Acryl 1-Step" => "one_step"
      },
      "army_painter" => {
        "Warpaints" => "warpaints", "Warpaints Tone" => "warpaints",
        "Quickshade Washes Set" => "warpaints", "Warpaints Primer" => "primer",
        "Warpaints Fanatic" => "fanatic", "Warpaints Fanatic Wash" => "fanatic",
        "Warpaints Air" => "air", "Speedpaint Set 2.0" => "speedpaint_2",
        "Historical" => "historical", "John Blanche Masterclass" => "john_blanche",
        "D&D Nolzur's Marvelous Pigments" => "dnd"
      }
    }.freeze

    def self.name(value)
      value.unicode_normalize(:nfkc).downcase.gsub(/[^[:alnum:]]/, "")
    end

    def self.paint_name(source, value)
      # Catalogs sometimes publish a second identity for a bottle-size listing.
      # Treat it as a potential existing match, never an automatic new color.
      value = value.sub(/\s+\(?\d+(?:\.\d+)?\s*ml\)?\z/i, "") if Sources.warhub?(source)
      name(value)
    end

    def self.family(source, range)
      if Sources.warhub?(source)
        normalized = name(range)
        return "acrylic" if source == "warhub_two_thin_coats" && %w[wave1 wave2 wave3 acrylic].include?(normalized)
        return normalized
      end
      FAMILIES.fetch(source).fetch(range, nil)
    end

    def self.code(source, value)
      return value unless Sources.warhub?(source)
      normalized = value.to_s.upcase.gsub(/[^[:alnum:]]/, "")
      return normalized.to_i.to_s if source == "warhub_reaper" && normalized.match?(/\A\d+\z/)
      normalized
    end

    def self.codes(source, payload)
      return [] if Sources.warhub?(source) && payload["has_product_code"] == false
      payload.values_at("code", "sku").map { |value| code(source, value) }
    end

    def self.producer_code?(source, code, paint_name: nil)
      if Sources.warhub?(source)
        return false if code.blank? || %w[null none unknown].include?(name(code))
        return name(code) != name(paint_name) if paint_name
        return true
      end
      pattern = (source == "monument") ? /\A(?:MPA-)?(?:\d{3}|S\d+)\z/ : /\A(?:WP|AW)\d{4}P?\z/
      code.to_s.match?(pattern)
    end
  end
end
