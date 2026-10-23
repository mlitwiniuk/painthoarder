# frozen_string_literal: true

# Catalogue (paints#index) filter chips and paint-detail helpers.
module CatalogueHelper
  COLOR_FAMILY_SWATCHES = {
    "Red" => "#A3161A", "Blue" => "#1F3A5A", "Green" => "#3E6B3A", "Yellow" => "#E3B53A",
    "Purple" => "#4B2E5C", "Cyan" => "#2C6E7A", "Brown" => "#8A5A2B", "White" => "#E6E1D4",
    "Black" => "#1C1A1A", "Gray" => "#6B6F72", "Metallic" => "#A07D3B"
  }.freeze

  SORT_OPTIONS = [
    ["Name A–Z", "name asc"],
    ["Brand A–Z", "product_line_brand_name asc"],
    ["Newest", "created_at desc"]
  ].freeze

  def color_family_label(category)
    (category == "Other") ? category : category.pluralize
  end

  def color_family_swatch_style(category)
    hex = COLOR_FAMILY_SWATCHES[category]
    hex ? "background-color: #{hex};" : "background: conic-gradient(#A3161A 0 25%, #E3B53A 0 50%, #3E6B3A 0 75%, #1F3A5A 0);"
  end

  # Catalogue URL keeping the current filters, with `changes` applied.
  # :brand / :line set the ransack ids (nil removes; a new brand drops the line),
  # any other key sets or (nil) removes a top-level param.
  def catalogue_path_with(changes = {})
    query = request.query_parameters.except("page", "format").deep_dup
    q = query["q"].is_a?(Hash) ? query["q"].dup : {}

    changes.each do |key, value|
      case key
      when :brand
        q.delete("product_line_id_eq")
        value ? q["product_line_brand_id_eq"] = value.to_s : q.delete("product_line_brand_id_eq")
      when :line
        value ? q["product_line_id_eq"] = value.to_s : q.delete("product_line_id_eq")
      else
        value.nil? ? query.delete(key.to_s) : query[key.to_s] = value
      end
    end

    query["q"] = q.presence
    paints_path(query.compact)
  end

  def catalogue_filter_summary(brand:, line:, color:)
    [brand&.name || line&.brand&.name, line&.name, (color_family_label(color.capitalize) if color.present?)].compact
  end

  # Same colour in other ranges of the brand, tutorials and the user's
  # projects that use it. Rendered by shared/_paint_show from several
  # controllers, so it is loaded here rather than in each of them.
  def paint_related(paint, user_paint)
    @paint_related ||= {}
    @paint_related[paint.id] ||= begin
      mentions = VideoPaint.joins(:video).merge(Video.completed)
        .where(paint_id: paint.id).includes(video: :video_paints).to_a
      project_usages = if user_signed_in? && user_paint.persisted? && !user_paint.virtual?
        PaintUsage.where(user_paint_id: user_paint.id)
          .includes(project_update: :project)
          .group_by { |usage| usage.project_update.project }
          .first(3)
      else
        []
      end

      {
        also_in: Paint.joins(:product_line)
          .where(product_lines: {brand_id: paint.product_line.brand_id}, name: paint.name)
          .where.not(id: paint.id)
          .includes(product_line: :brand)
          .order("product_lines.name").to_a,
        video_mentions: mentions.group_by(&:video).first(3),
        tutorial_count: mentions.map(&:video_id).uniq.size,
        owned_paint_ids: user_signed_in? ? current_user.user_paints.owned.pluck(:paint_id).to_set : Set.new,
        project_usages: project_usages
      }
    end
  end

  # "03:12, 11:40" for a video's mentions of a paint
  def video_timestamps(video_paints)
    video_paints.map(&:timestamp).compact_blank.uniq.first(3).join(", ")
  end
end
