# app/controllers/user_paints_controller.rb
class UserPaintsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_paint, only: [:show, :edit, :update]

  def index
    @query = current_user.user_paints.includes(paint: {product_line: :brand})

    # Apply filters
    @query = apply_filters(@query)

    # Set default sort
    @query = @query.order(created_at: :desc)

    # Get filtered results
    @user_paints = @query

    # Data for filter dropdowns - only include brands and product lines from user's owned paints
    @brands = Brand.joins(product_lines: {paints: {user_paints: :user}})
      .where(user_paints: {user_id: current_user.id})
      .distinct
      .order(:name)
    @product_lines = ProductLine.joins(paints: {user_paints: :user})
      .where(user_paints: {user_id: current_user.id})
      .includes(:brand)
      .distinct
      .order("brands.name, product_lines.name")
    @color_categories = ["Red", "Blue", "Green", "Yellow", "Purple", "Cyan", "White", "Black", "Gray", "Metallic", "Other"]

    # For tab counts
    @all_count = current_user.user_paints.count
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
    if params[:paint_id].present?
      @paint = Paint.find(params[:paint_id])
      @user_paint.paint = @paint
    end
  end

  def create
    @user_paint = current_user.user_paints.build(user_paint_params)

    respond_to do |format|
      if @user_paint.save
        format.html { redirect_to dashboard_path, notice: "Paint added to your collection!" }
        format.turbo_stream # Will render create.turbo_stream.erb that updates multiple parts of the UI
      else
        @brands = Brand.order(:name)

        @product_lines = if params[:user_paint][:brand_id].present?
          ProductLine.where(brand_id: params[:user_paint][:brand_id]).order(:name)
        else
          []
        end

        @paints = if params[:user_paint][:product_line_id].present?
          Paint.where(product_line_id: params[:user_paint][:product_line_id]).order(:name)
        else
          []
        end

        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("modal", partial: "user_paints/form", locals: {user_paint: @user_paint}) }
      end
    end
  end

  def show
    # No need to initialize similar paints arrays anymore
    # Similar paints will be loaded lazily by turbo_frames making requests to PaintsController#similar
    respond_to do |format|
      format.html
      format.turbo_stream
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
    @previous_status = @user_paint.status
    if @user_paint.update(user_paint_params)
      respond_to do |format|
        format.html { redirect_to user_paint_path(@user_paint), notice: "Paint was successfully updated." }
        format.turbo_stream {
          flash.now[:notice] = "Paint was successfully updated."
        }
      end
    else
      @brands = Brand.order(:name)
      @product_lines = @user_paint.paint&.product_line&.brand&.product_lines&.order(:name) || []
      @paints = @user_paint.paint&.product_line&.paints&.order(:name) || []

      respond_to do |format|
        format.html { render :edit }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("modal", partial: "user_paints/form", locals: {user_paint: @user_paint}) }
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
      query = query.joins(paint: {product_line: :brand})
        .where(brands: {id: params[:brand_id]})
    end

    if params[:product_line_id].present?
      query = query.joins(paint: :product_line)
        .where(product_lines: {id: params[:product_line_id]})
    end

    if params[:color].present?
      query = filter_by_color(query, params[:color].downcase)
    end

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      query = query.joins(paint: {product_line: :brand})
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
end
