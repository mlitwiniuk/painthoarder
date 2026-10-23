require "test_helper"

class RefreshPaintCatalogsJobTest < ActiveJob::TestCase
  test "scheduled refresh queues automatic publication once per producer" do
    assert_enqueued_jobs PaintCatalog::Sources::CONFIG.size, only: PaintCatalogSyncJob do
      assert_no_difference("Paint.count") { RefreshPaintCatalogsJob.perform_now }
    end
    assert_no_enqueued_jobs only: PaintCatalogSyncJob do
      RefreshPaintCatalogsJob.perform_now
    end
    assert_equal PaintCatalog::Sources::CONFIG.keys.sort, PaintCatalogRun.order(:source).pluck(:source)
    assert PaintCatalogRun.all.all?(&:auto_apply?)
  end

  test "enqueue failure releases the source for retry" do
    PaintCatalogSyncJob.stubs(:perform_later).returns(false)
    assert_raises(ActiveJob::EnqueueError) { RefreshPaintCatalogsJob.perform_now }
    assert_equal "failed", PaintCatalogRun.sole.status
    assert PaintCatalogRun.start!("monument").persisted?
  end

  test "interrupted fetches expire automatically and fresh active fetches are kept" do
    stale = PaintCatalogRun.start!("monument")
    stale.update_columns(status: "running", updated_at: 3.hours.ago)
    fresh = PaintCatalogRun.start!("army_painter")
    assert_enqueued_jobs PaintCatalog::Sources::CONFIG.size - 1, only: PaintCatalogSyncJob do
      RefreshPaintCatalogsJob.perform_now
    end
    assert_equal "failed", stale.reload.status
    assert_equal "queued", fresh.reload.status
    assert_equal 2, PaintCatalogRun.where(source: "monument").count
  end
end
