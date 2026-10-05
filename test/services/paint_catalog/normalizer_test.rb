require "test_helper"

class PaintCatalogNormalizerTest < ActiveSupport::TestCase
  def product(title:, sku:, vendor: "The Army Painter", type: "")
    {"id" => 1, "title" => title, "vendor" => vendor, "product_type" => type, "handle" => "test-paint",
     "variants" => [{"id" => 2, "sku" => sku, "available" => false}]}
  end

  test "Army Painter identifies untyped singles but excludes bundles with paint SKUs" do
    adapter = PaintCatalog::Normalizer.new("army_painter")
    rows, excluded = adapter.call([
      product(title: "Historical: Dark DAK Sand", sku: "WP4144P"),
      product(title: "Warpaints Fanatic: Complete Bundle", sku: "WP8102P"),
      product(title: "Wargamer: Layering Brush", sku: "BR7038P")
    ])
    assert_equal 1, rows.size
    assert_equal "Dark DAK Sand", rows.sole["name"]
    assert_equal "WP4144", rows.sole["code"]
    assert_equal "Historical", rows.sole["range"]
    assert_equal false, rows.sole["available"] # sold out is still a catalog paint
    assert_equal 2, excluded.size
  end

  test "Monument excludes other vendors and preserves range-specific codes" do
    rows, excluded = PaintCatalog::Normalizer.new("monument").call([
      product(title: "PRO Acryl 1-Step 512 - Rust", sku: "MPA-512", vendor: "Monument Hobbies", type: "Paint Singles"),
      product(title: "Expert Artist Red", sku: "TA-001", vendor: "Tri Art", type: "Paint Singles")
    ])
    assert_equal "512", rows.sole["code"]
    assert_equal "Rust", rows.sole["name"]
    assert_equal "Pro Acryl 1-Step", rows.sole["range"]
    assert_equal 1, excluded.size
  end

  test "auxiliaries are excluded and nested metallic prefixes are normalized" do
    rows, exclusions = PaintCatalog::Normalizer.new("army_painter").call([
      product(title: "Warpaints Air: Metallics: Bright Gold", sku: "AW1144P"),
      product(title: "Warpaints Air: Gloss Varnish, 100 ml", sku: "AW2005P")
    ])
    assert_equal "Bright Gold", rows.sole["name"]
    assert_equal 1, exclusions.size
  end

  test "multi-variant products cannot create duplicate paints" do
    item = product(title: "Speedpaint: Red", sku: "WP2001P")
    item["variants"] << {"id" => 3, "sku" => "WP2001P"}
    rows, excluded = PaintCatalog::Normalizer.new("army_painter").call([item])
    assert_empty rows
    assert_equal 1, excluded.size
  end

  test "medium shade names are paints while mixing mediums are not" do
    adapter = PaintCatalog::Normalizer.new("army_painter")
    rows, = adapter.call([product(title: "Historical: Medium Drab", sku: "WP4101P")])
    assert_equal "Medium Drab", rows.sole["name"]
    rows, exclusions = adapter.call([product(title: "Warpaints Air: Airbrush Medium, 100 ml", sku: "AW2001P")])
    assert_empty rows
    assert_equal 1, exclusions.size
  end
end
