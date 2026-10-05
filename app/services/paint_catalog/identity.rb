module PaintCatalog
  module Identity
    FIELDS = %w[name sku code range url].freeze
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

    def self.family(source, range)
      FAMILIES.fetch(source).fetch(range, nil)
    end

    def self.producer_code?(source, code)
      pattern = (source == "monument") ? /\A(?:MPA-)?(?:\d{3}|S\d+)\z/ : /\A(?:WP|AW)\d{4}P?\z/
      code.to_s.match?(pattern)
    end
  end
end
