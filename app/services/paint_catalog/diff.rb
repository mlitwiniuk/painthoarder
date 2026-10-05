module PaintCatalog
  class Diff
    def initialize(source)
      @source = source
      @paints = Brand.find_by(name: Sources.fetch(source).fetch(:brand))&.paints&.includes(:product_line)&.to_a || []
      @records = PaintCatalogRecord.where(source: source).includes(:paint).index_by(&:external_id)
      @rejections = PaintCatalogEntry.joins(:paint_catalog_run).includes(:paint)
        .where(paint_catalog_runs: {source: source}, status: %w[rejected applied]).order(id: :desc)
        .group_by(&:external_id).transform_values(&:first).select { |_id, entry| entry.status == "rejected" }
    end

    def call(payload)
      rejected = @rejections[payload.fetch("external_id")]
      if rejected && rejected.payload.slice(*Identity::FIELDS) == payload.slice(*Identity::FIELDS)
        return attributes(payload, rejected.action, rejected.paint).merge(status: "rejected",
          reviewed_by_id: rejected.reviewed_by_id, reviewed_at: rejected.reviewed_at,
          automation_reason: "Previously dismissed; producer details have not changed")
      end
      if (record = @records[payload.fetch("external_id")])
        paint = record.paint
        fields = Identity::FIELDS
        unchanged = paint.name == payload.fetch("name") && record.payload.slice(*fields) == payload.slice(*fields)
        action = unchanged ? "unchanged" : "update"
        return attributes(payload, action, paint)
      end

      codes = [payload.fetch("sku"), payload.fetch("code")]
      candidates = @paints.select { |paint| codes.include?(paint.code) }
      if candidates.empty?
        candidates = @paints.select do |paint|
          Identity.name(paint.name) == Identity.name(payload.fetch("name")) && same_family?(paint, payload)
        end
      end
      if candidates.one?
        paint = candidates.first
        # Never silently map a second producer identity to the same paint.
        if @records.values.none? { |record| record.paint_id == paint.id }
          return attributes(payload, "link", paint)
        end
      end
      if candidates.empty?
        candidates = @paints.select { |paint| Identity.name(paint.name) == Identity.name(payload.fetch("name")) }
        # Equal names in explicitly different families represent different paints.
        # Unknown legacy ranges remain exceptions rather than guessed matches.
        family = Identity.family(@source, payload.fetch("range"))
        if family && candidates.all? { |paint| (other = Identity.family(@source, paint.product_line.name)) && other != family }
          candidates = []
        end
      end
      return attributes(payload, "ambiguous").merge(candidate_ids: candidates.map(&:id)) if candidates.any?

      attributes(payload, "add")
    end

    private

    def same_family?(paint, payload)
      family = Identity.family(@source, payload.fetch("range"))
      (family && family == Identity.family(@source, paint.product_line.name)) || paint.product_line.name == payload.fetch("range")
    end

    def attributes(payload, action, paint = nil)
      {external_id: payload.fetch("external_id"), payload: payload, action: action,
       paint: paint, baseline: paint ? PaintCatalogEntry.paint_baseline(paint) : {}}
    end
  end
end
