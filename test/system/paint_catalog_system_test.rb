require "application_system_test_case"

class PaintCatalogSystemTest < ApplicationSystemTestCase
  setup do
    @admin = create(:confirmed_user, is_admin: true)
    @run = PaintCatalogRun.create!(source: "monument", status: "ready", finished_at: Time.current)
    @entry = @run.entries.create!(external_id: "512", action: "add", payload: {
      external_id: "512", product_id: "12", sku: "MPA-512", code: "512", name: "Rust",
      range: "Pro Acryl 1-Step", brand: "Monument", url: "https://monumenthobbies.com/products/rust"
    })
    login_as(@admin, scope: :user)
  end

  test "admin reviews and applies a catalog addition through the browser" do
    visit admin_paint_catalog_runs_path
    assert_selector "h1", text: "Producer catalog updates"
    click_on "Review"
    assert_current_path admin_paint_catalog_run_path(@run)
    assert_text "Rust"
    click_on "Review"
    assert_current_path admin_paint_catalog_entry_path(@entry)
    assert_text "Not supplied; existing swatch is preserved"
    click_on "Apply reviewed change"
    assert_no_text "Rust"
    click_on "Applied"
    assert_text "Rust"
    assert_equal "applied", @entry.reload.status
    paint = @entry.paint
    visit brand_product_line_paint_path(paint.brand, paint.product_line, paint.slug)
    assert_text "Swatch unknown"
    assert_text "Rust"
  end

  test "automatic publication leaves only exceptions on the dashboard" do
    @run.entries.create!(external_id: "999", action: "ambiguous", payload: @entry.payload.merge("name" => "Uncertain paint"))
    PaintCatalog::AutomaticApply.new(@run).call
    visit admin_paint_catalog_runs_path
    assert_text "Exceptions (1)"
    assert_text "Uncertain paint"
    assert_no_text "Rust"
    click_on "Resolve"
    assert_text "Multiple or uncertain existing matches"
    click_on "Dismiss this comparison"
    visit admin_paint_catalog_runs_path
    assert_text "No paint changes need a decision."
    assert_equal "automatic", @entry.reload.application_method
  end
end
