# app/controllers/paints_controller.rb
class PaintsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show similar]
  before_action :set_paint, only: [:show]
  include Filterable

  def index
    # Initialize ransack search
    @q = Paint.includes(product_line: :brand).ransack(params[:q])

    # Apply filters
    @query = apply_filters(@q.result)

    # Set default sort
    @query = @query.order(name: :asc)

    # Pagination with pagy
    @pagy, @paints = pagy(@query, items: 24)

    # Data for filter dropdowns
    @brands = Brand.order(:name)
    @product_lines = ProductLine.includes(:brand).order("brands.name, product_lines.name")
    @color_categories = ColorCategorization::COLOR_CATEGORIES

    # Get IDs of paints the user already has a relationship with
    @user_paint_ids = user_signed_in? ? current_user.user_paints.pluck(:paint_id) : []

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
    @page = (params[:page] || 1).to_i
    @per_page = params[:per_page] || 4
    @per_page = @per_page.to_i
    @similar_type = params[:similar_type] || "rgb"
    @source_paint = Paint.find(params[:id])

    # Parse brand_ids if provided in params
    if params[:brand_ids].present?
      @brand_ids = params[:brand_ids].split(",")
      # Save to user preferences if user is logged in
      current_user.similar_paint_brand_ids = @brand_ids if user_signed_in?
    elsif user_signed_in?
      # Use user's stored preferences
      @brand_ids = current_user.similar_paint_brand_ids
    else
      @brand_ids = nil
    end

    # Get all brands for the filter
    @brands = Brand.order(:name)

    # For user_provided similarity (paints from same brand)
    if @similar_type == "user"
      # Get the brand information
      brand_id = @source_paint.product_line.brand_id

      # Find paints from the same brand
      paints = Paint.joins(product_line: :brand)
        .where(product_lines: {brand_id: brand_id})
        .where.not(id: @source_paint.id)
        .includes(product_line: :brand)
        .order(name: :asc)
        .limit(@per_page)
        .offset((@page - 1) * @per_page)

      @similar_paints = map_paints_to_user_paints(paints)
    # For RGB similarity
    elsif @similar_type == "rgb"
      @similar_paints = find_rgb_similar_paints_for(@source_paint, @page, @per_page, @brand_ids)
    # For HSL similarity
    else # "hsl"
      @similar_paints = find_hsl_similar_paints_for(@source_paint, @page, @per_page, @brand_ids)
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  def set_paint
    @paint = Paint.includes(product_line: :brand).find(params[:id])
  end

  # Apply Ransack filters plus special filters from Filterable concern
  def apply_filters(query)
    # Brand filter
    if params[:q] && params[:q][:product_line_brand_id_eq].present?
      query = query.joins(product_line: :brand)
        .where(product_lines: {brand_id: params[:q][:product_line_brand_id_eq]})
    end

    # Product line filter
    if params[:q] && params[:q][:product_line_id_eq].present?
      query = query.where(product_line_id: params[:q][:product_line_id_eq])
    end

    # Apply special filters from concern (search and color)
    super
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

  # These methods can be called from other controllers
  public

  def find_user_similar_paints_for(paint, page, per_page)
    return [] unless paint

    # Get the brand information
    brand_id = paint.product_line.brand_id

    # Find paints from the same brand
    Paint.joins(product_line: :brand)
      .where(product_lines: {brand_id: brand_id})
      .where.not(id: paint.id)
      .includes(product_line: :brand)
      .order(name: :asc)
      .limit(per_page)
      .offset((page - 1) * per_page)
  end

  def find_rgb_similar_paints_for(paint, page, per_page, brand_ids = nil)
    return [] unless paint
    paint_id = paint.id

    red = paint.red
    green = paint.green
    blue = paint.blue

    # Get similar product line IDs for boosting
    similar_pl_ids = paint.product_line.similar_product_line_ids

    # Calculate Euclidean distance in RGB space, with boost for similar product lines
    distance_sql = "SQRT(POWER(paints.red - #{red.to_i}, 2) +
              POWER(paints.green - #{green.to_i}, 2) +
              POWER(paints.blue - #{blue.to_i}, 2))"

    if similar_pl_ids.any?
      boosted_sql = "CASE WHEN paints.product_line_id IN (#{similar_pl_ids.join(",")}) " \
                    "THEN #{distance_sql} * 0.7 ELSE #{distance_sql} END"
    else
      boosted_sql = distance_sql
    end

    paints = Paint.where.not(id: paint_id)
      .select("paints.*, #{distance_sql} AS color_distance, #{boosted_sql} AS boosted_distance")
      .includes(product_line: :brand)

    # Apply brand filter if provided
    if brand_ids.present?
      paints = paints.joins(product_line: :brand)
        .where(product_lines: {brand_id: brand_ids})
    end

    paints = paints.order("boosted_distance ASC")
      .limit(per_page)
      .offset((page - 1) * per_page)
    map_paints_to_user_paints(paints)
  end

  def find_hsl_similar_paints_for(paint, page, per_page, brand_ids = nil)
    return [] unless paint
    paint_id = paint.id

    red = paint.red
    green = paint.green
    blue = paint.blue

    # Get similar product line IDs for boosting
    similar_pl_ids = paint.product_line.similar_product_line_ids

    # Calculate weighted distance that emphasizes perceptual similarity
    distance_sql = "(ABS(paints.red - #{red.to_i}) +
              ABS(paints.green - #{green.to_i}) +
              ABS(paints.blue - #{blue.to_i}))"

    if similar_pl_ids.any?
      boosted_sql = "CASE WHEN paints.product_line_id IN (#{similar_pl_ids.join(",")}) " \
                    "THEN #{distance_sql} * 0.7 ELSE #{distance_sql} END"
    else
      boosted_sql = distance_sql
    end

    paints = Paint.where.not(id: paint_id)
      .select("paints.*, #{distance_sql} AS color_distance, #{boosted_sql} AS boosted_distance")
      .includes(product_line: :brand)

    # Apply brand filter if provided
    if brand_ids.present?
      paints = paints.joins(product_line: :brand)
        .where(product_lines: {brand_id: brand_ids})
    end

    paints = paints.order("boosted_distance ASC")
      .limit(per_page)
      .offset((page - 1) * per_page)
    map_paints_to_user_paints(paints)
  end
end
