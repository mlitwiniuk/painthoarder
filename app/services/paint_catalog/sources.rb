module PaintCatalog
  module Sources
    CONFIG = {
      "monument" => {label: "Monument / Pro Acryl", brand: "Monument",
                     host: "monumenthobbies.com", path: "/collections/paint-singles/products.json"},
      "army_painter" => {label: "The Army Painter", brand: "Army Painter",
                         host: "thearmypainter.com", path: "/products.json"}
    }.freeze

    def self.fetch(source)
      CONFIG.fetch(source)
    end
  end
end
