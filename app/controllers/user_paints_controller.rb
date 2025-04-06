# app/controllers/user_paints_controller.rb
class UserPaintsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_paint, only: [ :show, :edit, :update ]

  def index
      @query = current_user.user_paints.includes(paint: { product_line: :brand })

      # Apply filters
      @query = apply_filters(@query)

      # Set default sort
      @query = @query.order(created_at: :desc)

      # Get filtered results
      @user_paints = @query

      # Data for filter dropdowns
      @brands = Brand.order(:name)
      @product_lines = ProductLine.includes(:brand).order("brands.name, product_lines.name")
      @color_categories = [ "Red", "Blue", "Green", "Yellow", "Purple", "Cyan", "White", "Black", "Gray", "Metallic", "Other" ]

      # For tab counts
      @owned_count = current_user.user_paints.owned.count
      @wishlist_count = current_user.user_paints.wishlist.count
      @avoid_count = current_user.user_paints.avoid.count

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

  def new
    @user_paint = UserPaint.new
    @brands = Brand.order(:name)
    @product_lines = []
    @paints = []
  end

  def create
    @user_paint = current_user.user_paints.build(user_paint_params)

    respond_to do |format|
      if @user_paint.save
        format.html { redirect_to dashboard_path, notice: "Paint added to your collection!" }
        format.turbo_stream { render turbo_stream: turbo_stream.prepend("user_paints", partial: "user_paints/user_paint", locals: { user_paint: @user_paint }) }
      else
        @brands = Brand.order(:name)

        if params[:user_paint][:brand_id].present?
          @product_lines = ProductLine.where(brand_id: params[:user_paint][:brand_id]).order(:name)
        else
          @product_lines = []
        end

        if params[:user_paint][:product_line_id].present?
          @paints = Paint.where(product_line_id: params[:user_paint][:product_line_id]).order(:name)
        else
          @paints = []
        end

        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def show
    @page = (params[:page] || 1).to_i
    @per_page = 12
    @similar_type = params[:similar_type] || "user"

    # Load similar paints based on the requested type
    case @similar_type
    when "rgb"
      @similar_paints = find_rgb_similar_paints(@page, @per_page)
    when "hsl"
      @similar_paints = find_hsl_similar_paints(@page, @per_page)
    else
      @similar_paints = find_user_similar_paints(@page, @per_page)
    end

    @user_similar_paints = []
    @rgb_similar_paints = []
    @hsl_similar_paints = []

    # Only for the initial page load
    unless params[:page]
      @rgb_similar_paints = find_rgb_similar_paints(1, 4)
      @hsl_similar_paints = find_hsl_similar_paints(1, 4)
      @user_similar_paints = find_user_similar_paints(1, 4)
    end

    respond_to do |format|
      format.html
      format.turbo_stream do
        # For debugging - make sure you can see these messages in the server log
        Rails.logger.debug "Turbo request for similar paints: #{@similar_type}, page: #{@page}"
        Rails.logger.debug "Found #{@similar_paints.size} similar paints"
        # Just use the standard turbo_stream template - don't render in the controller
      end
    end
  end

  def edit
    @brands = Brand.order(:name)
    @product_lines = []
    @paints = []
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def update
    if @user_paint.update(user_paint_params)
      respond_to do |format|
        format.html { redirect_to user_paints_path, notice: "Paint was successfully updated." }
        format.turbo_stream { flash.now[:notice] = "Paint was successfully updated." }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@user_paint, :edit), partial: "user_paints/form", locals: { user_paint: @user_paint }) }
      end
    end
  end

  # Update and destroy actions remain the same...

  private

  def set_user_paint
    @user_paint = current_user.user_paints.find(params[:id])
  end

  def user_paint_params
    params.require(:user_paint).permit(:paint_id, :status, :notes, :purchase_date, :purchase_price)
  end


  def apply_filters(query)
    # Safely apply filters
    if params[:status].present?
      query = query.where(status: params[:status])
    end

    if params[:brand_id].present?
      query = query.joins(paint: { product_line: :brand })
                  .where(brands: { id: params[:brand_id] })
    end

    if params[:product_line_id].present?
      query = query.joins(paint: :product_line)
                  .where(product_lines: { id: params[:product_line_id] })
    end

    if params[:color].present?
      query = filter_by_color(query, params[:color].downcase)
    end

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      query = query.joins(paint: { product_line: :brand })
                  .where("paints.name ILIKE ? OR brands.name ILIKE ? OR product_lines.name ILIKE ?",
                        search_term, search_term, search_term)
    end

    query
  end

  def filter_by_color(query, color)
    case color
    when "red"
      query.joins(:paint).where("paints.red > 200 AND paints.green < 100 AND paints.blue < 100")
    when "blue"
      query.joins(:paint).where("paints.red < 100 AND paints.green < 100 AND paints.blue > 200")
    when "green"
      query.joins(:paint).where("paints.red < 100 AND paints.green > 200 AND paints.blue < 100")
    when "yellow"
      query.joins(:paint).where("paints.red > 200 AND paints.green > 200 AND paints.blue < 100")
    when "purple"
      query.joins(:paint).where("paints.red > 150 AND paints.green < 100 AND paints.blue > 150")
    when "cyan"
      query.joins(:paint).where("paints.red < 100 AND paints.green > 150 AND paints.blue > 150")
    when "white"
      query.joins(:paint).where("paints.red > 180 AND paints.green > 180 AND paints.blue > 180")
    when "black"
      query.joins(:paint).where("paints.red < 50 AND paints.green < 50 AND paints.blue < 50")
    when "gray"
      query.joins(:paint).where("ABS(paints.red - paints.green) < 30 AND ABS(paints.green - paints.blue) < 30 AND ABS(paints.red - paints.blue) < 30")
    when "metallic"
      query.joins(:paint).where("paints.name ILIKE '%metal%' OR paints.name ILIKE '%silver%' OR paints.name ILIKE '%gold%'")
    else
      query
    end
  end

  # Helper methods for finding similar paints
  def find_user_similar_paints(page, per_page)
    # For now, this is a placeholder - would typically be based on user input
    # or some relationship between paints that the user has defined
    # For now, we'll just return other paints from the same brand
    return [] unless @user_paint.paint

    # Get the brand and product line information
    brand_id = @user_paint.paint.product_line.brand_id
    paint_id = @user_paint.paint.id

    # Find paints from the same brand
    paints = Paint.joins(product_line: :brand)
      .where(product_lines: { brand_id: brand_id })
      .where.not(id: paint_id)
      .includes(product_line: :brand)
      .order(name: :asc)
      .limit(per_page)
      .offset((page - 1) * per_page)

    # Convert paints to user_paints where they exist, or create virtual ones
    map_paints_to_user_paints(paints)
  end

  def find_rgb_similar_paints(page, per_page)
    # Find paints with similar RGB values
    return [] unless @user_paint.paint

    # Skip the current paint in the results
    paint_id = @user_paint.paint.id

    # Use PostgreSQL's distance calculation between RGB values
    red = @user_paint.paint.red
    green = @user_paint.paint.green
    blue = @user_paint.paint.blue

    # Calculate Euclidean distance in RGB space
    paints = Paint.where.not(id: paint_id)
      .select("paints.*, SQRT(POWER(paints.red - #{red}, 2) +
              POWER(paints.green - #{green}, 2) +
              POWER(paints.blue - #{blue}, 2)) AS color_distance")
      .includes(product_line: :brand)
      .order("color_distance ASC")
      .limit(per_page)
      .offset((page - 1) * per_page)

    # Convert paints to user_paints where they exist, or create virtual ones
    map_paints_to_user_paints(paints)
  end

  def find_hsl_similar_paints(page, per_page)
    # Find paints with similar HSL values
    return [] unless @user_paint.paint

    # Skip the current paint in the results
    paint_id = @user_paint.paint.id

    # Use RGB for now as a placeholder, since we don't have HSL values directly
    # In a real implementation, we'd convert RGB to HSL and compare in HSL space
    red = @user_paint.paint.red
    green = @user_paint.paint.green
    blue = @user_paint.paint.blue

    # Calculate weighted distance that emphasizes color similarities that would be
    # perceptually similar in HSL space
    paints = Paint.where.not(id: paint_id)
      .select("paints.*, (
              ABS(paints.red - #{red}) +
              ABS(paints.green - #{green}) +
              ABS(paints.blue - #{blue})) AS color_distance")
      .includes(product_line: :brand)
      .order("color_distance ASC")
      .limit(per_page)
      .offset((page - 1) * per_page)

    # Convert paints to user_paints where they exist, or create virtual ones
    map_paints_to_user_paints(paints)
  end

  # Helper method to convert Paint objects to UserPaint objects
  # If the user already has the paint in their collection, use that
  # Otherwise, create a virtual UserPaint object for display purposes
  def map_paints_to_user_paints(paints)
    user_paint_map = current_user.user_paints.where(paint_id: paints.map(&:id)).index_by(&:paint_id)

    paints.map do |paint|
      user_paint_map[paint.id] || UserPaint.new(paint: paint, user: current_user, virtual: true)
    end
  end
end
