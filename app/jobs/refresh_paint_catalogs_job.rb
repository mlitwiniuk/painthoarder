class RefreshPaintCatalogsJob < ApplicationJob
  queue_as :default

  def perform
    PaintCatalog::Sources::CONFIG.each_key do |source|
      PaintCatalogRun.where(source: source, status: %w[queued running]).where("updated_at < ?", 2.hours.ago)
        .update_all(status: "failed", error_message: "Fetch expired; automatically scheduled a replacement",
          finished_at: Time.current, updated_at: Time.current)
      begin
        run = PaintCatalogRun.start!(source)
      rescue ActiveRecord::RecordNotUnique
        next # A manual or scheduled fetch is already queued/running.
      end
      begin
        job = PaintCatalogSyncJob.perform_later(run)
        raise ActiveJob::EnqueueError, "Catalog fetch was not queued" unless job
      rescue => error
        run.update!(status: "failed", error_message: "Could not enqueue catalog fetch", finished_at: Time.current)
        raise error
      end
    end
  end
end
