module PaintCatalog
  class AutomaticApply
    def initialize(run)
      @run = run
    end

    def call
      @run.reload
      return unless @run.auto_apply? && @run.reviewable?
      return if @run.automation_status == "completed"
      if @run.large_drop?
        @run.entries.where(status: "pending").update_all(automation_reason: "Catalog size dropped by more than 20%; automatic publishing paused")
        @run.update!(automation_status: "blocked", automation_error: nil)
        return
      end
      # Commit each paint separately so a large refresh does not hold SQLite's
      # write lock for the whole catalog. Retries resume the remaining entries.
      @run.entries.where(status: "pending").find_each do |entry|
        PaintCatalogEntry.transaction(requires_new: true) do
          Apply.call(entry, automatic: true)
        end
      rescue Apply::Conflict => error
        entry.reload.update!(automation_reason: error.message)
      end
      @run.update!(automation_status: "completed", automation_error: nil)
    rescue => error
      # Preserve completed entries and the snapshot for an idempotent retry.
      @run.reload.update!(automation_status: "failed", automation_error: "#{error.class}: #{error.message}".truncate(500))
      Rails.error.report(error, handled: true, context: {catalog_run_id: @run.id})
    end
  end
end
