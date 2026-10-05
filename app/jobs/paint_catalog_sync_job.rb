class PaintCatalogSyncJob < ApplicationJob
  queue_as :default

  def perform(run)
    PaintCatalog::Sync.new(run).call
  end
end
