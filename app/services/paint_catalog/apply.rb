module PaintCatalog
  class Apply
    class Conflict < StandardError; end

    def self.call(entry, reviewer: nil, paint_id: nil, create_separate: false, acknowledge_warnings: false, automatic: false)
      raise Conflict, "An administrator must review catalog changes" unless automatic || reviewer&.admin?
      entry.with_lock do
        return entry.paint if entry.status == "applied"
        run = entry.paint_catalog_run
        raise Conflict, "This entry has already been dismissed" unless entry.status == "pending"
        raise Conflict, "Fetch a fresh catalog and review its latest completed batch" unless run.reviewable?
        if !automatic && run.warnings.any? && !acknowledge_warnings
          raise Conflict, "Review and acknowledge the batch warnings first"
        end
        payload = entry.payload
        existing = PaintCatalogRecord.find_by(source: run.source, external_id: entry.external_id)
        if existing && existing.paint_id != entry.paint_id
          raise Conflict, "This producer identity was linked after the comparison; fetch again"
        end
        paint = entry.paint
        if paint && PaintCatalogEntry.paint_baseline(paint.reload) != entry.baseline
          raise Conflict, "The paint changed after this comparison; fetch again"
        end
        if automatic && (reason = AutomaticPolicy.block_reason(entry))
          raise Conflict, reason
        end
        if entry.action == "ambiguous"
          brand = Brand.find_by!(name: Sources.fetch(run.source).fetch(:brand))
          raise Conflict, "Choose either an existing paint or a separate paint, not both" if paint_id.present? && create_separate
          paint = brand.paints.find(paint_id) if paint_id.present?
          raise Conflict, "Choose an existing paint or explicitly create a separate paint" unless paint || create_separate
        elsif paint_id.present? || create_separate
          raise Conflict, "Manual matching is only available for ambiguous entries"
        end
        if paint.nil?
          # Recheck a proposed addition against the current database, including
          # earlier entries applied from the same batch.
          current = Diff.new(run.source).call(payload)
          if current[:action] != "add" && !(entry.action == "ambiguous" && create_separate)
            raise Conflict, "A possible match appeared after the comparison; fetch again"
          end
          brand = Brand.find_or_create_by!(name: Sources.fetch(run.source).fetch(:brand))
          line = brand.product_lines.find_or_create_by!(name: payload.fetch("range"))
          if line.paints.where(code: [payload.fetch("code"), payload.fetch("sku")]).exists?
            raise Conflict, "That code already exists in the range; link the existing paint"
          end
          paint = line.paints.create!({name: payload.fetch("name"), code: payload.fetch("code"), color_source: "unknown"}
            .merge(swatch_attributes(run.source, payload)))
        end
        other = PaintCatalogRecord.where(source: run.source, paint_id: paint.id).where.not(external_id: entry.external_id)
        raise Conflict, "This paint is already linked to another producer identity" if other.exists?

        record = existing || PaintCatalogRecord.new(source: run.source, external_id: entry.external_id, paint: paint)
        aliases = (record.aliases + [paint.name, paint.code, payload.fetch("sku")]).uniq
        # Existing codes, range membership, known colors, and associations survive.
        changes = {}
        changes[:name] = payload.fetch("name") if paint.name != payload.fetch("name")
        changes.merge!(swatch_attributes(run.source, payload)) unless paint.color_known?
        paint.update!(changes) if changes.any?
        record.update!(sku: payload.fetch("sku"), source_url: payload.fetch("url"), payload: payload,
          aliases: aliases, last_seen_at: run.finished_at)
        entry.update!(paint: paint, status: "applied", reviewed_by: reviewer, reviewed_at: Time.current,
          application_method: automatic ? "automatic" : "manual", automation_reason: nil)
        paint
      end
    rescue ActiveRecord::RecordNotUnique
      raise Conflict, "Another reviewer applied a conflicting match; fetch again"
    end

    def self.swatch_attributes(source, payload)
      return {} unless Sources.warhub?(source) && payload["hex"].present?
      hex = payload.fetch("hex")
      raise Conflict, "Invalid catalog swatch" unless hex.match?(/\A#[0-9a-fA-F]{6}\z/)
      red, green, blue = hex.delete_prefix("#").scan(/../).map { |channel| channel.to_i(16) }
      {red: red, green: green, blue: blue, color_source: "warhub"}
    end
  end
end
