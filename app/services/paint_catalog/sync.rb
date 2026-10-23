module PaintCatalog
  class Sync
    def initialize(run, client: nil)
      @run = run
      @client = client || Sources.client(run.source)
    end

    def call
      fetch
      AutomaticApply.new(@run).call if @run.reload.status == "ready" && @run.auto_apply?
      @run
    end

    private

    def fetch
      claimed = @run.with_lock do
        next false unless @run.status == "queued"
        @run.update!(status: "running")
        true
      end
      return unless claimed

      response = @client.fetch(@run.source)
      products = Sources.warhub?(@run.source) ? response.fetch("paints") : response
      metadata = Sources.warhub?(@run.source) ? response.except("paints") : {}
      payloads, exclusions = Sources.normalizer(@run.source).call(products)
      raise ShopifyClient::FetchError, "No recognizable paints; producer format may have changed" if payloads.empty?
      @run.with_lock do
        raise ShopifyClient::FetchError, "This run has been cancelled" unless @run.status == "running"
        warnings = warnings_for(payloads)
        diff = Diff.new(@run.source)
        payloads.each { |payload| @run.entries.create!(diff.call(payload)) }
        PaintCatalogRecord.where(source: @run.source, external_id: payloads.pluck("external_id"))
          .update_all(last_seen_at: Time.current)
        @run.update!(status: "ready", snapshot: products, source_metadata: metadata, exclusions: exclusions,
          warnings: warnings, finished_at: Time.current)
      end
      @run
    rescue => error
      @run.update!(status: "failed", error_message: "#{error.class}: #{error.message}".truncate(500), finished_at: Time.current)
      Rails.error.report(error, handled: true, context: {catalog_run_id: @run.id})
      @run
    end

    def warnings_for(payloads)
      warnings = []
      if @run.large_drop?(payloads.size)
        warnings << "Paint count dropped by more than 20% since the previous completed fetch. Check excluded products before applying."
      end
      missing = PaintCatalogRecord.where(source: @run.source).where.not(external_id: payloads.pluck("external_id")).count
      warnings << "#{missing} linked paints were not found. Their catalog records have been preserved; no discontinuation is inferred." if missing.positive?
      warnings
    end
  end
end
