module PaintCatalog
  class AutomaticPolicy
    def self.block_reason(entry)
      run = entry.paint_catalog_run
      return "Catalog size dropped by more than 20%; automatic publishing paused" if run.large_drop?
      return "Multiple or uncertain existing matches" if entry.action == "ambiguous"
      if entry.action == "link"
        paint = entry.paint
        code_matches = Identity.codes(run.source, entry.payload).include?(Identity.code(run.source, paint.code))
        return nil if code_matches && Identity.paint_name(run.source, paint.name) == Identity.paint_name(run.source, entry.payload.fetch("name"))
        if Array(entry.payload["variant_codes"]).many? && !code_matches
          return "Source has multiple coded variants with this name; existing variant is unknown"
        end
        family = Identity.family(run.source, entry.payload.fetch("range"))
        unless family && family == Identity.family(run.source, paint.product_line.name)
          return "Existing code belongs to a different or unknown paint family"
        end
        if entry.payload["has_product_code"] != false && Identity.producer_code?(run.source, paint.code, paint_name: paint.name) && !code_matches
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
