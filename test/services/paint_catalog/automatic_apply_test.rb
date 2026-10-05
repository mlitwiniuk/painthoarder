require "test_helper"

class PaintCatalogAutomaticApplyTest < ActiveSupport::TestCase
  setup do
    @brand = create(:brand, name: "Monument")
    @line = create(:product_line, brand: @brand, name: "Monument Pro Acrylic Paints")
  end

  def product(id: 1, code: "001", name: "White")
    {"id" => id, "title" => "#{code}-Pro Acryl #{name}", "vendor" => "Monument Hobbies",
     "product_type" => "Paint Singles", "handle" => "paint-#{id}",
     "variants" => [{"id" => id + 100, "sku" => "MPA-#{code}", "available" => true}]}
  end

  def sync(products, auto_apply: true)
    run = PaintCatalogRun.start!("monument", auto_apply: auto_apply)
    client = mock
    client.expects(:fetch).returns(products)
    PaintCatalog::Sync.new(run, client: client).call
  end

  test "automatic refresh links and adds without an admin while preserving user data" do
    paint = create(:paint, name: "White", code: "001", product_line: @line)
    owned = create(:user_paint, paint: paint)
    baseline = paint.attributes
    run = sync([product, product(id: 2, code: "002", name: "Black")])
    assert_equal "completed", run.automation_status
    assert_equal 2, run.entries.where(status: "applied", application_method: "automatic").count
    assert_equal baseline, paint.reload.attributes
    assert_equal paint.id, owned.reload.paint_id
    added = Paint.find_by!(code: "002")
    assert_equal "unknown", added.color_source
    assert_nil added.hex_color
    assert run.entries.all? { |entry| entry.reviewed_by_id.nil? }
    assert_no_difference "Paint.count" do
      PaintCatalog::AutomaticApply.new(run).call
      sync([product, product(id: 2, code: "002", name: "Black")])
    end
  end

  test "producer renames follow stable identities automatically" do
    run = sync([product])
    paint = run.entries.sole.paint
    later = sync([product(code: "002", name: "Renamed White")])
    assert_equal "applied", later.entries.sole.status
    assert_equal "Renamed White", paint.reload.name
    assert_equal "001", paint.code
    assert_equal 1, Paint.count
  end

  test "local name corrections are preserved and surfaced as exceptions" do
    run = sync([product])
    paint = run.entries.sole.paint
    paint.update!(name: "Verified local name")
    later = sync([product(name: "Producer rename")])
    assert_equal "pending", later.entries.sole.status
    assert_match(/edited locally/, later.entries.sole.automation_reason)
    assert_equal "Verified local name", paint.reload.name
  end

  test "ambiguous records do not prevent unrelated paints from publishing" do
    create_list(:paint, 2, product_line: @line, code: "001", name: "White")
    run = sync([product, product(id: 2, code: "002", name: "Black")])
    assert_equal "completed", run.automation_status
    assert_equal 1, run.entries.where(status: "pending").count
    assert_equal 1, run.entries.where(status: "applied").count
    assert_match(/uncertain/, run.entries.find_by!(status: "pending").automation_reason)
  end

  test "same names in explicitly different families become separate paints" do
    existing = create(:paint, name: "Blue", code: "005", product_line: @line)
    item = product(code: "500")
    item["title"] = "PRO Acryl 1-Step 500 - Blue"
    run = sync([item])
    assert_equal "add", run.entries.sole.action
    assert_equal "applied", run.entries.sole.status
    assert_not_equal existing.id, run.entries.sole.paint_id
    assert_equal "Pro Acryl 1-Step", run.entries.sole.paint.product_line.name
  end

  test "a code match across families and a name match with conflicting codes are held" do
    create(:paint, name: "White", code: "002", product_line: @line)
    run = sync([product])
    assert_match(/code differs/, run.entries.sole.automation_reason)
    other_line = create(:product_line, brand: @brand, name: "Pro Acryl 1-Step")
    create(:paint, name: "Other formula", code: "003", product_line: other_line)
    run = sync([product(code: "003")])
    assert_match(/different or unknown paint family/, run.entries.sole.automation_reason)
    assert_empty PaintCatalogRecord.all
  end

  test "matching code and name can link a paint in an old subcategory" do
    line = create(:product_line, brand: @brand, name: "Monument Pro Acrylic Wash")
    paint = create(:paint, product_line: line, name: "Black Wash", code: "200")
    run = sync([product(code: "200", name: "Black Wash")])
    assert_equal "applied", run.entries.sole.status
    assert_equal paint.id, run.entries.sole.paint_id
    assert_equal line.id, paint.reload.product_line_id
  end

  test "a suspicious count drop pauses publishing but keeps the successful snapshot" do
    sync([product, product(id: 2, code: "002", name: "Black")])
    run = sync([product(name: "Renamed White")])
    assert_equal "ready", run.status
    assert_equal "blocked", run.automation_status
    assert_equal "White", Paint.find_by!(code: "001").name
    assert_equal 1, run.snapshot.size
    repeated = sync([product(name: "Renamed White")])
    assert_equal "blocked", repeated.automation_status
    assert_equal "White", Paint.find_by!(code: "001").name
  end

  test "ordinary missing products do not stop healthy updates or delete anything" do
    items = 5.times.map { |i| product(id: i + 1, code: format("%03d", i + 1), name: "Paint #{i}") }
    sync(items)
    items.shift
    items.first["title"] = "002-Pro Acryl Renamed"
    run = sync(items)
    assert_equal "completed", run.automation_status
    assert_equal 5, Paint.count
    assert_equal "Renamed", Paint.find_by!(code: "002").name
    assert run.warnings.any?
  end

  test "dismissals persist across refreshes and changed producer details reopen them" do
    admin = create(:confirmed_user, is_admin: true)
    run = sync([product], auto_apply: false)
    run.entries.sole.update!(status: "rejected", reviewed_by: admin, reviewed_at: Time.current)
    later = sync([product])
    assert_equal "rejected", later.entries.sole.status
    assert_equal 0, Paint.count
    changed = sync([product(name: "New White")])
    assert_equal "applied", changed.entries.sole.status
    # A later successful decision supersedes the original rejection.
    reverted = sync([product])
    assert_equal "applied", reverted.entries.sole.status
    assert_equal "White", Paint.sole.name
  end

  test "unexpected publication failures preserve successful entries and resume on retry" do
    run = sync([product, product(id: 2, code: "002", name: "Black")], auto_apply: false)
    run.update!(auto_apply: true)
    PaintCatalog::AutomaticPolicy.stubs(:block_reason).with(run.entries.first).returns(nil)
    PaintCatalog::AutomaticPolicy.stubs(:block_reason).with(run.entries.last).raises("unexpected failure")
    PaintCatalog::AutomaticApply.new(run).call
    assert_equal "ready", run.reload.status
    assert_equal "failed", run.automation_status
    assert_equal 1, Paint.count
    assert_equal 1, run.entries.where(status: "pending").count
    PaintCatalog::AutomaticPolicy.unstub(:block_reason)
    PaintCatalog::AutomaticApply.new(run).call
    assert_equal "completed", run.reload.automation_status
    assert_equal 2, Paint.count
  end

  test "preview batches remain read only even if automatic publication is called" do
    run = sync([product], auto_apply: false)
    PaintCatalog::AutomaticApply.new(run).call
    assert_equal 0, Paint.count
    assert_equal "pending", run.entries.sole.status
  end
end
