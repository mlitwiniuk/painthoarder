# app/controllers/paints_controller.rb
class PaintsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show similar]
  before_action :set_paint, only: [:show]
  include Filterable

  def index
    # Initialize ransack search (sanitize params to reject non-scalar values)
    @q = Paint.includes(product_line: :brand).ransack(sanitize_ransack_params(params[:q]))

    # Apply filters
    @query = apply_filters(@q.result)

    # "Hide paints I own"
    @hide_owned = user_signed_in? && params[:hide_owned] == "1"
    @query = @query.where.not(id: current_user.user_paints.owned.select(:paint_id)) if @hide_owned

    # Set default sort
    @query = @query.order(name: :asc)

    # Pagination with pagy
    @pagy, @paints = pagy(@query, limit: 24)

    # Data for filter chips
    @brands = Brand.order(:name)
    @color_categories = ColorCategorization::COLOR_CATEGORIES
    filters = sanitize_ransack_params(params[:q]) || {}
    @selected_brand = Brand.find_by(id: filters["product_line_brand_id_eq"]) if filters["product_line_brand_id_eq"].present?
    @selected_line = ProductLine.includes(:brand).find_by(id: filters["product_line_id_eq"]) if filters["product_line_id_eq"].present?
    @brand_lines = (@selected_brand || @selected_line&.brand)&.product_lines&.order(:name) || []
    @total_paints = Paint.count
    @total_brands = Brand.count

    # Owned / wanted / virtual UserPaint per paint for the cards
    @catalog_user_paints = map_paints_to_user_paints(@paints)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    redirect_to brand_product_line_paint_path(
      @paint.product_line.brand,
      @paint.product_line,
      @paint.slug
    ), status: :moved_permanently, allow_other_host: false
  end

  def search
    @paints = Paint.full_search(params[:query]).limit(20)

    # Get IDs of paints the user already has a relationship with
    @user_paint_ids = current_user.user_paints.pluck(:paint_id)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def similar
    @source_paint = Paint.find(params[:id])
    @page = (params[:page] || 1).to_i.clamp(1, 100)
    @per_page = (params[:per_page] || 4).to_i.clamp(1, PaintSimilarityQuery::MAX_RESULTS)
    @strategy = params[:similar_type].presence_in(PaintSimilarityQuery::STRATEGIES) ||
      PaintSimilarityQuery::DEFAULT_STRATEGY

    @brand_ids = resolve_similar_brand_ids
    @brands = Brand.order(:name)

    query = PaintSimilarityQuery.new(@source_paint, strategy: @strategy, brand_ids: @brand_ids)
    results = query.page(@page, @per_page)
    @scores = results.to_h { |result| [result[:paint].id, result[:score]] }
    @similar_paints = map_paints_to_user_paints(results.map { |result| result[:paint] })
    @has_more = query.more_after?(@page, @per_page)
    @total_count = query.total_count

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # PATCH /paints/:id/collection_status
  # Sets the signed-in user's status for this paint from the catalogue or the
  # paint page ("none" removes it from the rack) and refreshes it in place.
  def collection_status
    @paint = Paint.includes(product_line: :brand).find(params[:id])
    status = params[:status].to_s
    @user_paint = current_user.user_paints.find_by(paint_id: @paint.id)

    if status == "none"
      @user_paint&.destroy
      @user_paint = UserPaint.new(paint: @paint, user: current_user, virtual: true)
    elsif UserPaint.statuses.key?(status)
      @user_paint ||= current_user.user_paints.build(paint: @paint)
      @user_paint.update!(status: status)
    else
      return head :unprocessable_entity
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: directory_paint_path(@paint) }
    end
  end

  private

  def directory_paint_path(paint)
    brand_product_line_paint_path(paint.product_line.brand, paint.product_line, paint.slug)
  end

  def set_paint
    @paint = Paint.includes(product_line: :brand).find(params[:id])
  end

  # Apply Ransack filters plus special filters from Filterable concern
  def apply_filters(query)
    q = sanitize_ransack_params(params[:q])

    # Brand filter
    if q && q[:product_line_brand_id_eq].present?
      query = query.joins(product_line: :brand)
        .where(product_lines: {brand_id: q[:product_line_brand_id_eq]})
    end

    # Product line filter
    if q && q[:product_line_id_eq].present?
      query = query.where(product_line_id: q[:product_line_id_eq])
    end

    # Apply special filters from concern (search and color)
    super
  end

  def sanitize_ransack_params(q_params)
    return nil unless q_params.is_a?(ActionController::Parameters) || q_params.is_a?(Hash)
    q_params.to_unsafe_h.select { |_, v| v.is_a?(String) || v.is_a?(Numeric) }
  end

  # Helper method to convert Paint objects to UserPaint objects
  # If the user already has the paint in their collection, use that
  # Otherwise, create a virtual UserPaint object for display purposes
  def map_paints_to_user_paints(paints)
    if user_signed_in?
      user_paint_map = current_user.user_paints.where(paint_id: paints.map(&:id)).index_by(&:paint_id)

      paints.map do |paint|
        user_paint_map[paint.id] || UserPaint.new(paint: paint, user: current_user, virtual: true)
      end
    else
      paints.map { |paint| UserPaint.new(paint: paint, virtual: true) }
    end
  end

  # Brand filter for similar paints: explicit params win and are persisted,
  # otherwise fall back to the signed-in user's stored preference.
  def resolve_similar_brand_ids
    if params[:brand_ids] == "all"
      # Explicitly widen to every brand (and remember it)
      current_user.similar_paint_brand_ids = ["all"] if user_signed_in?
      nil
    elsif params[:brand_ids].present?
      ids = params[:brand_ids].split(",")
      current_user.similar_paint_brand_ids = ids if user_signed_in?
      ids
    elsif user_signed_in?
      ids = current_user.similar_paint_brand_ids
      (ids == ["all"]) ? nil : ids
    end
  end
end
