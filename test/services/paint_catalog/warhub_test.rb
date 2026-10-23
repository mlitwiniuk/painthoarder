require "test_helper"

class PaintCatalogWarhubTest < ActiveSupport::TestCase
  def row(id: "vallejo/white", brand: "Vallejo", name: "White", range: "Model Color", code: "70.951", hex: "#fefefe", **extra)
    {"id" => id, "brand" => brand, "name" => name, "range" => range, "category" => "paint", "role" => "colour",
     "productCode" => code, "hex" => hex, "status" => "current"}.merge(extra.stringify_keys)
  end

  def sync(rows, source: "warhub_vallejo")
    client = mock
    client.expects(:fetch).returns({"paints" => rows, "version" => "2026.10.4", "verified_sha256" => "test"})
    PaintCatalog::Sync.new(PaintCatalogRun.start!(source), client: client).call
  end

  test "all 19 additional brands map to the intended existing catalog names" do
    assert_equal 19, PaintCatalog::Sources::WARHUB_BRANDS.size
    assert_equal "Duncan", PaintCatalog::Sources.fetch("warhub_two_thin_coats")[:brand]
    assert_equal "AK", PaintCatalog::Sources.fetch("warhub_ak_interactive")[:brand]
    assert_equal "A K R C", PaintCatalog::Sources.fetch("warhub_ak_real_color")[:brand]
    assert_equal "Mig", PaintCatalog::Sources.fetch("warhub_ammo_mig")[:brand]
    assert_not PaintCatalog::Sources::CONFIG.key?("warhub_army_painter")
    assert_not PaintCatalog::Sources::CONFIG.key?("warhub_monument_pro_acryl")
  end

  test "automatic additions use validated WarHub swatches with provenance and stable identity" do
    run = sync([row])
    paint = run.entries.sole.paint
    assert_equal "completed", run.automation_status
    assert_equal "#fefefe", paint.hex_color
    assert_equal "warhub", paint.color_source
    assert_not_nil paint.lab_l
    assert_equal "2026.10.4", run.source_metadata["version"]
    assert_equal "vallejo/white", PaintCatalogRecord.sole.external_id
    assert_no_difference("Paint.count") { sync([row]) }
    paint.update!(red: 200)
    assert_equal "manual", paint.color_source
  end

  test "linking and later source color changes preserve existing swatches and collections" do
    brand = create(:brand, name: "Vallejo")
    line = create(:product_line, brand: brand, name: "Model Color")
    paint = create(:paint, product_line: line, name: "White", code: "70951", red: 190, green: 191, blue: 192)
    owned = create(:user_paint, paint: paint)
    sync([row])
    assert_equal paint.id, PaintCatalogRecord.sole.paint_id
    sync([row(hex: "#ffffff")])
    assert_equal [190, 191, 192], paint.reload.values_at(:red, :green, :blue)
    assert_equal "legacy_dataset", paint.color_source
    assert_equal paint.id, owned.reload.paint_id
  end

  test "unknown swatches are filled once while a missing swatch stays unknown" do
    brand = create(:brand, name: "Vallejo")
    line = create(:product_line, brand: brand, name: "Model Color")
    paint = create(:paint, product_line: line, name: "White", code: "70.951", red: nil, green: nil, blue: nil)
    sync([row])
    assert_equal "warhub", paint.reload.color_source
    assert_equal "#fefefe", paint.hex_color
    run = sync([row, row(id: "vallejo/black", name: "Black", code: "70.950", hex: nil)])
    assert_nil run.entries.find_by!(external_id: "vallejo/black").paint.hex_color
  end

  test "code-free paints match by name and range without crossing formulas" do
    brand = create(:brand, name: "Citadel Colour")
    air = create(:product_line, brand: brand, name: "Air")
    base = create(:product_line, brand: brand, name: "Base")
    create(:paint, product_line: air, name: "Abaddon Black", code: "Abaddon Black")
    paint = create(:paint, product_line: base, name: "Abaddon Black", code: "Abaddon Black")
    run = sync([row(id: "citadel-colour/abaddon-black-base", brand: "Citadel Colour", name: "Abaddon Black", range: "Base", code: nil)], source: "warhub_citadel_colour")
    assert_equal "applied", run.entries.sole.status
    assert_equal paint.id, run.entries.sole.paint_id
    assert_equal 2, Paint.count
  end

  test "Two Thin Coats matches the legacy Duncan wave ranges" do
    brand = create(:brand, name: "Duncan")
    line = create(:product_line, brand: brand, name: "Wave 2")
    paint = create(:paint, product_line: line, name: "White", code: "White")
    run = sync([row(id: "two-thin-coats/white", brand: "Two Thin Coats", range: "Acrylic", code: nil)], source: "warhub_two_thin_coats")
    assert_equal paint.id, run.entries.sole.paint_id
    assert_equal "Wave 2", paint.reload.product_line.name
  end

  test "auxiliaries are excluded while discontinued paints remain cataloged" do
    run = sync([row(status: "discontinued"), row(id: "vallejo/medium", role: "medium")])
    assert_equal 1, run.exclusions.size
    assert_equal "applied", run.entries.sole.status
    assert_equal "discontinued", PaintCatalogRecord.sole.payload["status"]
  end

  test "bottle-size listings cannot automatically duplicate the same color" do
    run = sync([
      row(id: "green-stuff-world/acid-green", brand: "Green Stuff World", name: "Acid Green", range: "Dipping Inks", code: nil),
      row(id: "green-stuff-world/acid-green-17-ml", brand: "Green Stuff World", name: "Acid Green 17 ml", range: "Dipping Inks", code: "4234")
    ], source: "warhub_green_stuff_world")
    assert_equal 1, Paint.count
    assert_equal 1, run.entries.where(status: "applied").count
    assert_equal 1, run.entries.where(status: "pending").count
  end

  test "simultaneous coded variants are separate even with identical approximate swatches" do
    run = sync([row(id: "vallejo/aged-metal-base", name: "Aged Metal", range: "True Metallic Metal", code: "77.119", hex: "#55502f"),
      row(id: "vallejo/aged-metal-shade", name: "Aged Metal", range: "True Metallic Metal", code: "77.139", hex: "#55502f"),
      row(id: "vallejo/aged-metal-air", name: "Aged Metal", range: "True Metallic Metal", code: "77.179", hex: "#55502f")])
    assert_equal 3, Paint.count
    assert_equal 3, run.entries.where(status: "applied").count
    assert_equal %w[77.119 77.139 77.179], Paint.order(:code).pluck(:code)
  end

  test "bad colors repeated identities and cross-brand data cannot publish" do
    [[row(hex: "red;url(evil)")], [row, row], [row(brand: "Other")]].each do |products|
      run = sync(products)
      assert_equal "failed", run.status
      assert_empty run.entries
      assert_equal 0, Paint.count
    end
  end
end
