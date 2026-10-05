module PaintCatalog
  class AutomaticPolicy
    def self.block_reason(entry)
      run = entry.paint_catalog_run
      return "Catalog size dropped by more than 20%; automatic publishing paused" if run.large_drop?
      return "Multiple or uncertain existing matches" if entry.action == "ambiguous"
      if entry.action == "link"
        paint = entry.paint
        code_matches = entry.payload.values_at("code", "sku").include?(paint.code)
        return nil if code_matches && Identity.name(paint.name) == Identity.name(entry.payload.fetch("name"))
        family = Identity.family(run.source, entry.payload.fetch("range"))
        unless family && family == Identity.family(run.source, paint.product_line.name)
          return "Existing code belongs to a different or unknown paint family"
        end
        if Identity.producer_code?(run.source, paint.code) && !code_matches
          return "Name matches but the existing producer code differs"
        end
      elsif %w[update unchanged].include?(entry.action)
        record = PaintCatalogRecord.find_by!(source: run.source, external_id: entry.external_id)
        if Identity.name(entry.paint.name) != Identity.name(record.payload.fetch("name"))
          return "Paint name was edited locally; preserving the local correction"
        end
      end
      nil
    end
  end
end
