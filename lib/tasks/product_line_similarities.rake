namespace :product_lines do
  desc "Seed product line similarity mappings (idempotent)"
  task seed_similarities: :environment do
    similarity_groups = {
      "Contrast/One-coat" => [
        ["Citadel Colour", "Contrast"],
        ["Army Painter", "Speedpaint Set 2.0"],
        ["Vallejo", "Xpress Color"],
        ["Vallejo", "Xpress Color Intense"],
        ["Scale75", "Instant Colors Range"],
        ["Green Stuff World", "Dipping Inks"],
        ["AK", "Ink (3rd Gen)"],
        ["Warcolours", "One-coat paints"]
      ],
      "Standard opaque" => [
        ["Citadel Colour", "Base"],
        ["Citadel Colour", "Layer"],
        ["Army Painter", "Warpaints Fanatic"],
        ["Army Painter", "Warpaints"],
        ["Vallejo", "Game Color"],
        ["Vallejo", "Model Color"],
        ["Scale75", "Scale Color Range"],
        ["Scale75", "Fantasy & Games Range"],
        ["AK", "Standard (3rd Gen)"],
        ["Green Stuff World", "Acrylic Colors"],
        ["Reaper", "Master Series Paints Core Colors"],
        ["Reaper", "Master Series Paints Bones"],
        ["P3", "Privateer Press Formula P3"],
        ["Warcolours", "Layer paints"],
        ["Monument", "Monument Pro Acrylic Paints"],
        ["Creature", "Monument Pro Acryl"]
      ],
      "Washes/Shades" => [
        ["Citadel Colour", "Shade"],
        ["Army Painter", "Warpaints Fanatic Wash"],
        ["Army Painter", "Quickshade Washes Set"],
        ["Vallejo", "Game Color Wash"],
        ["Vallejo", "Wash FX"],
        ["Green Stuff World", "Wash Ink"],
        ["Scale75", "Inktensity Range"],
        ["Reaper", "Master Series Paints Core Colors Wash"],
        ["P3", "Privateer Press Formula P3 Wash"],
        ["Warcolours", "Inks for Shading and Glazing"],
        ["Monument", "Monument Pro Acrylic Wash"]
      ],
      "Airbrush" => [
        ["Citadel Colour", "Air"],
        ["Army Painter", "Warpaints Air"],
        ["Vallejo", "Game Air"],
        ["Vallejo", "Model Air"],
        ["AK", "Air (3rd Gen)"]
      ],
      "Metallic" => [
        ["Vallejo", "Metal Color"],
        ["Vallejo", "Liquid Gold"],
        ["Scale75", "Metal N Alchemy Range"],
        ["AK", "Metallic (3rd Gen)"],
        ["Green Stuff World", "Metallic Colors"],
        ["Warcolours", "Metallic paints"],
        ["Army Painter", "Metallic Colours Paint Set"]
      ],
      "Primers" => [
        ["Army Painter", "Warpaints Primer"],
        ["Vallejo", "Surface Primer"],
        ["AK", "Primer (3rd Gen)"],
        ["Reaper", "Master Series Paints Core Colors Primer"],
        ["Monument", "Monument Pro Acrylic Primer"]
      ],
      "Special FX" => [
        ["Citadel Colour", "Technical"],
        ["Vallejo", "Game Color Special FX"],
        ["Vallejo", "Weathering FX"],
        ["Scale75", "FX Range"]
      ],
      "Glazes/Transparent" => [
        ["Citadel Colour", "Glaze"],
        ["Warcolours", "Glazing paints"],
        ["Warcolours", "Transparent paints"],
        ["Creature", "Monument Pro Acryl Transparent"]
      ]
    }

    # Clear stale records
    puts "Clearing existing product line similarities..."
    ProductLineSimilarity.delete_all

    total_created = 0

    similarity_groups.each do |group_name, lines|
      puts "\nProcessing group: #{group_name}"

      # Resolve product line IDs
      resolved = lines.filter_map do |brand_name, line_name|
        brand = Brand.find_by(name: brand_name)
        unless brand
          puts "  ⚠ Brand not found: #{brand_name}"
          next
        end

        pl = brand.product_lines.find_by(name: line_name)
        unless pl
          puts "  ⚠ Product line not found: #{brand_name} → #{line_name}"
          next
        end

        pl
      end

      # Create bidirectional pairs
      resolved.combination(2).each do |a, b|
        ProductLineSimilarity.find_or_create_by!(product_line: a, similar_product_line: b)
        ProductLineSimilarity.find_or_create_by!(product_line: b, similar_product_line: a)
        total_created += 2
      end

      puts "  ✓ #{resolved.size} lines resolved, #{resolved.combination(2).count * 2} similarity records"
    end

    puts "\nDone! #{ProductLineSimilarity.count} total similarity records."
  end
end
