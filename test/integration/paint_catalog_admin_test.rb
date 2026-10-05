require "test_helper"

class PaintCatalogAdminTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @admin = create(:confirmed_user, is_admin: true)
    @run = PaintCatalogRun.create!(source: "monument", status: "ready", finished_at: Time.current)
    @entry = @run.entries.create!(external_id: "100", action: "add", payload: {
      external_id: "100", product_id: "1", sku: "MPA-512", code: "512", name: "Rust",
      range: "Pro Acryl 1-Step", brand: "Monument", url: "https://monumenthobbies.com/products/rust"
    })
  end

  test "anonymous and regular users cannot fetch or apply producer data" do
    get admin_paint_catalog_runs_path
    assert_redirected_to new_user_session_path
    sign_in create(:confirmed_user)
    get admin_paint_catalog_runs_path
    assert_response :forbidden
    post admin_paint_catalog_runs_path, params: {source: "monument"}
    assert_response :forbidden
    patch admin_paint_catalog_entry_path(@entry), params: {decision: "apply"}
    assert_response :forbidden
    post apply_admin_paint_catalog_run_path(@run), params: {entry_ids: [@entry.id]}
    assert_response :forbidden
    assert_equal 0, Paint.count
  end

  test "admin can review a batch and explicitly apply selected additions" do
    sign_in @admin
    get admin_paint_catalog_runs_path
    assert_response :success
    get admin_paint_catalog_run_path(@run)
    assert_response :success
    assert_select "input[name='entry_ids[]']", count: 1
    get admin_paint_catalog_entry_path(@entry)
    assert_response :success
    assert_difference "Paint.count", 1 do
      post apply_admin_paint_catalog_run_path(@run), params: {entry_ids: [@entry.id]}
    end
    assert_redirected_to admin_paint_catalog_run_path(@run)
    assert_equal "applied", @entry.reload.status
    assert_equal @admin.id, @entry.reviewed_by_id
  end

  test "admin fetch queues work and rejects unknown producer URLs" do
    sign_in @admin
    assert_enqueued_with(job: PaintCatalogSyncJob) do
      post admin_paint_catalog_runs_path, params: {source: "monument"}
    end
    assert_response :see_other
    post admin_paint_catalog_runs_path, params: {source: "http://localhost"}
    assert_response :bad_request
    post admin_paint_catalog_runs_path, params: {source: "monument"}
    assert_redirected_to admin_paint_catalog_runs_path
  end

  test "bulk apply is atomic and cannot select entries from another run" do
    sign_in @admin
    other = PaintCatalogRun.create!(source: "army_painter", status: "ready", finished_at: Time.current)
    foreign_entry = other.entries.create!(external_id: "200", action: "ambiguous", payload: @entry.payload)
    assert_no_difference "Paint.count" do
      post apply_admin_paint_catalog_run_path(@run), params: {entry_ids: [@entry.id, foreign_entry.id]}
    end
    ambiguous = @run.entries.create!(external_id: "201", action: "ambiguous", payload: @entry.payload)
    assert_no_difference "Paint.count" do
      post apply_admin_paint_catalog_run_path(@run), params: {entry_ids: [@entry.id, ambiguous.id]}
    end
    assert_equal "pending", @entry.reload.status
    assert_empty PaintCatalogRecord.all
  end

  test "dismissal does not publish a paint and cancellation releases an active fetch" do
    sign_in @admin
    patch admin_paint_catalog_entry_path(@entry), params: {decision: "reject"}
    assert_equal "rejected", @entry.reload.status
    assert_equal 0, Paint.count
    active = PaintCatalogRun.start!("monument")
    post cancel_admin_paint_catalog_run_path(active)
    assert_equal "failed", active.reload.status
    assert PaintCatalogRun.start!("monument").persisted?
  end
end
