require "test_helper"

class PaintCatalogTest < ActiveSupport::TestCase
  setup do
    @admin = create(:confirmed_user, is_admin: true)
    @brand = create(:brand, name: "Monument")
    @line = create(:product_line, brand: @brand, name: "Monument Pro Acrylic Paints")
  end

  def product(id: 100, sku: "MPA-001", name: "001-Pro Acryl Bold Titanium White")
    {"id" => id, "title" => name, "vendor" => "Monument Hobbies", "product_type" => "Paint Singles",
     "handle" => "paint-#{id}", "updated_at" => "2026-10-01T12:00:00Z",
     "variants" => [{"id" => id + 1000, "sku" => sku, "available" => true}]}
  end

  def sync(products)
    run = PaintCatalogRun.start!("monument", auto_apply: false)
    client = mock
    client.expects(:fetch).with("monument").returns(products)
    PaintCatalog::Sync.new(run, client: client).call
  end

  test "fetch stages an exact match without changing paints or collections" do
    paint = create(:paint, product_line: @line, code: "001", name: "Old white", red: 240)
    collection = create(:user_paint, paint: paint)
    baseline = paint.attributes
    run = sync([product])
    assert_equal "ready", run.status
    assert_equal baseline, paint.reload.attributes
    assert_equal "link", run.entries.sole.action
    assert_equal [product], run.snapshot
    assert_no_difference "Paint.count" do
      PaintCatalog::Apply.call(run.entries.sole, reviewer: @admin)
    end
    assert_equal paint.id, collection.reload.paint_id
    assert_equal "Bold Titanium White", paint.reload.name
    assert_equal "001", paint.code
    assert_equal 240, paint.red
    assert_equal @line.id, paint.product_line_id
    assert_includes PaintCatalogRecord.sole.aliases, "Old white"
    assert_equal @admin, run.entries.sole.reviewed_by
  end

  test "adds unknown swatches and applies idempotently" do
    run = sync([product(sku: "MPA-512", name: "PRO Acryl 1-Step 512 - Rust")])
    entry = run.entries.sole
    assert_difference "Paint.count", 1 do
      2.times { PaintCatalog::Apply.call(entry, reviewer: @admin) }
    end
    paint = entry.reload.paint
    assert_equal "Rust", paint.name
    assert_equal "512", paint.code
    assert_equal "Pro Acryl 1-Step", paint.product_line.name
    assert_nil paint.hex_color
    assert_nil paint.lab_l
    assert_equal "unknown", paint.color_source
    assert_equal 1, PaintCatalogRecord.count
  end

  test "stable producer identity survives a rename and SKU change" do
    run = sync([product])
    paint = PaintCatalog::Apply.call(run.entries.sole, reviewer: @admin)
    changed = product(sku: "MPA-002", name: "002-Pro Acryl Renamed White")
    later = sync([changed])
    assert_equal "update", later.entries.sole.action
    assert_no_difference "Paint.count" do
      assert_equal paint, PaintCatalog::Apply.call(later.entries.sole, reviewer: @admin)
    end
    assert_equal "001", paint.reload.code
    assert_equal "Renamed White", paint.name
    assert_equal "MPA-002", PaintCatalogRecord.sole.sku
  end

  test "ambiguous matches require a decision and cannot cross brands" do
    first = create(:paint, product_line: @line, code: "001")
    create(:paint, product_line: create(:product_line, brand: @brand), code: "001")
    entry = sync([product]).entries.sole
    assert_equal "ambiguous", entry.action
    assert_raises(PaintCatalog::Apply::Conflict) { PaintCatalog::Apply.call(entry, reviewer: @admin) }
    outsider = create(:paint)
    assert_raises(ActiveRecord::RecordNotFound) do
      PaintCatalog::Apply.call(entry, reviewer: @admin, paint_id: outsider.id)
    end
    assert_equal first, PaintCatalog::Apply.call(entry, reviewer: @admin, paint_id: first.id)
  end

  test "producer metadata changes require review even when the paint name is unchanged" do
    run = sync([product])
    paint = PaintCatalog::Apply.call(run.entries.sole, reviewer: @admin)
    assert_equal "unchanged", sync([product]).entries.sole.action
    later = sync([product(sku: "MPA-002", name: "002-Pro Acryl Bold Titanium White")])
    assert_equal "update", later.entries.sole.action
    PaintCatalog::Apply.call(later.entries.sole, reviewer: @admin)
    assert_equal "MPA-002", PaintCatalogRecord.sole.sku
    assert_equal "001", paint.reload.code
  end

  test "stale paint edits and superseded batches cannot be applied" do
    paint = create(:paint, product_line: @line, code: "001")
    entry = sync([product]).entries.sole
    paint.update!(name: "Hand corrected")
    assert_raises(PaintCatalog::Apply::Conflict) { PaintCatalog::Apply.call(entry, reviewer: @admin) }
    sync([product])
    assert_not entry.paint_catalog_run.reviewable?
    assert_raises(PaintCatalog::Apply::Conflict) { PaintCatalog::Apply.call(entry.reload, reviewer: @admin) }
  end

  test "failed and empty fetches never produce applicable entries" do
    run = sync([])
    assert_equal "failed", run.status
    assert_empty run.entries
    run = PaintCatalogRun.start!("monument")
    client = mock
    client.expects(:fetch).raises(Net::ReadTimeout)
    PaintCatalog::Sync.new(run, client: client).call
    assert_equal "failed", run.reload.status
    assert_empty run.entries
    assert_equal 0, Paint.count
  end

  test "missing products and large count drops require acknowledgement and never delete paints" do
    first = sync([product, product(id: 101, sku: "MPA-002", name: "002-Pro Acryl Black")])
    first.entries.each { |entry| PaintCatalog::Apply.call(entry, reviewer: @admin) }
    later = sync([product(name: "001-Pro Acryl White")])
    assert_equal 2, later.warnings.size
    assert_equal 2, Paint.count
    assert_raises(PaintCatalog::Apply::Conflict) { PaintCatalog::Apply.call(later.entries.sole, reviewer: @admin) }
    PaintCatalog::Apply.call(later.entries.sole, reviewer: @admin, acknowledge_warnings: true)
    assert_equal 2, Paint.count
  end

  test "concurrent source fetches and second identity links are blocked" do
    run = PaintCatalogRun.start!("monument")
    assert_raises(ActiveRecord::RecordNotUnique) { PaintCatalogRun.start!("monument") }
    run.update!(status: "failed")
    first = sync([product])
    PaintCatalog::Apply.call(first.entries.sole, reviewer: @admin)
    later = sync([product(id: 101)])
    assert_equal "ambiguous", later.entries.sole.action
    assert_raises(PaintCatalog::Apply::Conflict) do
      PaintCatalog::Apply.call(later.entries.sole, reviewer: @admin, paint_id: Paint.sole.id, acknowledge_warnings: true)
    end
  end

  test "batch additions recheck matches created since comparison" do
    entry = sync([product]).entries.sole
    create(:paint, product_line: @line, code: "001")
    assert_raises(PaintCatalog::Apply::Conflict) { PaintCatalog::Apply.call(entry, reviewer: @admin) }
    assert_empty PaintCatalogRecord.all
  end

  test "non-admin reviewers cannot write the catalog" do
    entry = sync([product]).entries.sole
    assert_raises(PaintCatalog::Apply::Conflict) do
      PaintCatalog::Apply.call(entry, reviewer: create(:confirmed_user))
    end
  end
end
