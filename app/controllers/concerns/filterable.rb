# frozen_string_literal: true

# Shared filtering functionality for controllers that filter collections of paints
module Filterable
  extend ActiveSupport::Concern
  include ColorCategorization

  # Apply filters to query that cannot be handled by ransack
  def apply_filters(query)
    # Status filter - only applies to UserPaints
    if respond_to?(:filter_by_status) && params[:status].present?
      query = filter_by_status(query)
    end

    # Search filter - use Paint's full_search scope for better search results
    if params[:search].present?
      query = filter_by_search(query)
    end

    # Color filter - use ColorCategorization module
    if params[:color].present?
      query = filter_by_color(query, params[:color].downcase)
    end

    query
  end

  # Filter by color using ColorCategorization module
  def filter_by_color(query, color)
    model_name = (controller_name.classify == "Paint") ? "paints" : "paints"
    # The query needs to have :paint joined if this is a UserPaint query
    if controller_name.classify == "UserPaint"
      query = query.joins(:paint) unless query.to_sql.include?('INNER JOIN "paints"')
    end
    ColorCategorization.filter_query(query, color, model: model_name)
  end

  # UserPaints need status filtering
  def filter_by_status(query)
    query.where(status: params[:status])
  end

  # Filter by search using Paint's full_search scope
  def filter_by_search(query)
    paint_ids = Paint.full_search(params[:search]).pluck(:id)
    if controller_name.classify == "Paint"
      query.where(id: paint_ids)
    else
      query.where(paint_id: paint_ids)
    end
  end
end
