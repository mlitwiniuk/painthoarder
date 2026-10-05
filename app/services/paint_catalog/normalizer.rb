module PaintCatalog
  class Normalizer
    ARMY_RANGES = {
      "Warpaints Fanatic" => "Warpaints Fanatic",
      "Warpaints Fanatic Metallic" => "Warpaints Fanatic",
      "Warpaints Fanatic Effects" => "Warpaints Fanatic",
      "Warpaints Fanatic Wash" => "Warpaints Fanatic Wash",
      "Speedpaint" => "Speedpaint Set 2.0",
      "Warpaints Air" => "Warpaints Air",
      "Warpaints Air Metallics" => "Warpaints Air",
      "Warpaints Air Fluorescent" => "Warpaints Air",
      "Warpaints" => "Warpaints", "Warpaints Metallics" => "Warpaints",
      "Warpaints Effects" => "Warpaints", "Historical" => "Historical",
      "John Blanche Masterclass" => "John Blanche Masterclass"
    }.freeze
    AUXILIARY = /\b(varnish|primer|cleaner|retarder|thinner)\b|\bmedium(?:\s*,?\s*\d+\s*ml)?\z/i
    PACK = /\b(bundle|set|triad|combo|pack|rack)\b/i

    def initialize(source)
      @source = source
      @config = Sources.fetch(source)
    end

    # Retain excluded products and reasons alongside accepted observations.
    def call(products)
      accepted = []
      exclusions = []
      products.each do |product|
        normalized, reason = normalize(product)
        if normalized
          accepted << normalized
        else
          exclusions << {"title" => product["title"], "product_id" => product["id"], "reason" => reason}
        end
      end
      ids = accepted.map { |row| row.fetch("external_id") }
      raise ShopifyClient::FetchError, "Repeated variant identity" unless ids.uniq.size == ids.size
      [accepted, exclusions]
    end

    private

    def normalize(product)
      title = product.fetch("title").strip
      variants = product.fetch("variants")
      return [nil, "Multiple variants require review of packaging"] unless variants.size == 1
      variant = variants.first
      sku = variant.fetch("sku", "").to_s.strip
      return [nil, "Set, bundle, or multipack"] if title.match?(PACK)
      return [nil, "Auxiliary or primer; outside the first paint-only adapter"] if title.match?(AUXILIARY)

      name, range, code = if @source == "monument"
        monument(product, title, sku)
      else
        army(product, title, sku)
      end
      return [nil, "Unrecognized producer, paint range, or SKU"] unless name.present? && range.present?

      unless [product.fetch("id"), variant.fetch("id")].all? { |id| id.to_s.match?(/\A[1-9]\d*\z/) }
        raise ShopifyClient::FetchError, "Missing or invalid producer identity"
      end
      handle = product.fetch("handle")
      raise ShopifyClient::FetchError, "Invalid product handle" unless handle.match?(/\A[a-z0-9-]+\z/)
      [{"external_id" => variant.fetch("id").to_s, "product_id" => product.fetch("id").to_s,
        "sku" => sku, "code" => code, "name" => name.strip, "range" => range,
        "brand" => @config.fetch(:brand), "url" => "https://#{@config.fetch(:host)}/products/#{handle}",
        "available" => variant["available"], "producer_updated_at" => product["updated_at"]}, nil]
    end

    def monument(product, title, sku)
      return unless product["vendor"] == "Monument Hobbies" && product["product_type"] == "Paint Singles"
      case sku
      when /\AMPA-(5\d{2})\z/
        [title.sub(/\APRO Acryl 1-Step \d+\s*-\s*/i, ""), "Pro Acryl 1-Step", sku.delete_prefix("MPA-")]
      when /\AMPA-(S\d+)\z/
        [title.sub(/\AS\d+\s*-\s*/, ""), "Monument Pro Signature Series", sku.delete_prefix("MPA-")]
      when /\AMPA-(\d{3})\z/
        [title.sub(/\A\d+\s*-\s*Pro Acryl\s*/i, ""), "Monument Pro Acrylic Paints", sku.delete_prefix("MPA-")]
      end
    end

    def army(product, title, sku)
      return unless ["The Army Painter", "The Army Painter (B2C)"].include?(product["vendor"])
      return unless sku.match?(/\A(?:WP|AW)[1-4]\d{3}P\z/)
      prefix, name = title.split(/:\s*|,\s*/, 2)
      range = ARMY_RANGES[prefix]
      [name.delete_prefix("Metallics: "), range, sku.delete_suffix("P")] if range && name
    end
  end
end
