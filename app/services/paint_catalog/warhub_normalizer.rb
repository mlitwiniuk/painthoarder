module PaintCatalog
  class WarhubNormalizer
    def initialize(source)
      @config = Sources.fetch(source)
    end

    def call(products)
      accepted = []
      exclusions = []
      seen = Set.new
      products.each do |product|
        unless product.is_a?(Hash) && product["brand"] == @config.fetch(:upstream_brand)
          raise HttpClient::FetchError, "Unexpected WarHub brand or record"
        end
        id = product.fetch("id")
        unless id.is_a?(String) && id.match?(/\A#{Regexp.escape(@config.fetch(:partition))}\/[a-z0-9-]+\z/) && seen.add?(id)
          raise HttpClient::FetchError, "Invalid or repeated WarHub identity"
        end
        unless product["category"] == "paint" && product["role"] == "colour" && product["colourless"] != true
          exclusions << {"title" => product["name"], "product_id" => id, "reason" => "Not a color paint (#{product["role"]})"}
          next
        end
        name = product.fetch("name")
        range = product.fetch("range")
        unless [name, range].all? { |value| value.is_a?(String) && value.strip.present? }
          raise HttpClient::FetchError, "WarHub paint is missing a name or range"
        end
        hex = product["hex"]
        if hex && (!hex.is_a?(String) || !hex.match?(/\A#[0-9a-fA-F]{6}\z/))
          raise HttpClient::FetchError, "Invalid WarHub color value"
        end
        code = product["productCode"]&.to_s&.strip.presence
        accepted << {"external_id" => id, "product_id" => id, "sku" => code || id,
          "code" => code || name.strip, "has_product_code" => code.present?,
          "name" => name.strip, "range" => range.strip, "brand" => @config.fetch(:brand),
          "url" => "https://warhub.github.io/warhub-catalog/paints/by-brand/#{@config.fetch(:partition)}.json",
          "hex" => hex&.downcase, "color_source" => "warhub", "status" => product["status"],
          "availability" => product["availability"], "volume_ml" => product["volumeMl"]}
      end
      # Explicit simultaneous codes at the same volume are catalog variants,
      # even if display names or approximate swatches are identical.
      accepted.group_by { |row| [row["range"], Identity.name(row["name"]), row["volume_ml"]] }.each_value do |group|
        if group.many? && group.all? { |row| row["has_product_code"] } && group.pluck("code").uniq.size == group.size
          group.each { |row| row["variant_codes"] = group.pluck("code").sort }
        end
      end
      [accepted, exclusions]
    end
  end
end
