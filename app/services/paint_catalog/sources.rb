module PaintCatalog
  module Sources
    WARHUB_BRANDS = {
      "ak-interactive" => ["AK", "AK Interactive"],
      "ak-real-color" => ["A K R C", "AK Real Color"],
      "ammo-mig" => ["Mig", "AMMO by Mig Jimenez"],
      "citadel-colour" => ["Citadel Colour", "Citadel Colour"],
      "coat-darmes" => ["Coat D Armes", "Coat D'Armes"],
      "foundry" => ["Foundry", "Foundry"],
      "green-stuff-world" => ["Green Stuff World", "Green Stuff World"],
      "humbrol" => ["Humbrol", "Humbrol"],
      "kimera-kolors" => ["Kimera Kolors", "Kimera Kolors"],
      "mission-models" => ["Mission Models", "Mission Models"],
      "mr-hobby" => ["Mr Hobby", "Mr Hobby"],
      "p3" => ["P3", "P3 (Privateer Press)"],
      "reaper" => ["Reaper", "Reaper"],
      "scale75" => ["Scale75", "Scale75"],
      "tamiya" => ["Tamiya", "Tamiya"],
      "turbo-dork" => ["Turbo Dork", "Turbo Dork"],
      "two-thin-coats" => ["Duncan", "Two Thin Coats"],
      "vallejo" => ["Vallejo", "Vallejo"],
      "warcolours" => ["Warcolours", "Warcolours"]
    }.freeze

    CONFIG = {
      "monument" => {label: "Monument / Pro Acryl", brand: "Monument",
                     host: "monumenthobbies.com", path: "/collections/paint-singles/products.json"},
      "army_painter" => {label: "The Army Painter", brand: "Army Painter",
                         host: "thearmypainter.com", path: "/products.json"}
    }.merge(WARHUB_BRANDS.to_h do |partition, (brand, label)|
      ["warhub_#{partition.tr("-", "_")}", {label: "#{label} (WarHub)", brand: brand,
                                            adapter: :warhub, partition: partition, upstream_brand: label}]
    end).freeze

    def self.fetch(source)
      CONFIG.fetch(source)
    end

    def self.warhub?(source)
      fetch(source)[:adapter] == :warhub
    end

    def self.client(source)
      warhub?(source) ? WarhubClient.new : ShopifyClient.new
    end

    def self.normalizer(source)
      warhub?(source) ? WarhubNormalizer.new(source) : Normalizer.new(source)
    end
  end
end
