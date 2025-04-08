# app/controllers/user_paints_controller.rb
class UserPaintsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_paint, only: [:show, :edit, :update, :destroy]
  include Filterable

  def index
    # Initialize ransack search
    @q = current_user.user_paints.includes(paint: {product_line: :brand}).ransack(params[:q])

    # Apply additional filters that can't be handled by ransack
    @query = apply_filters(@q.result)

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
    @color_categories = ColorCategorization::COLOR_CATEGORIES

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
    @search_term = params[:search_term].to_s

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

  def bulk_import
    # Just render the form
  end

  def color_wheel
    # Get all the user's paints with their associated paint data
    @user_paints = current_user.user_paints.includes(paint: {product_line: :brand}).all

    respond_to do |format|
      format.html
    end
  end

  def bulk_search
    @paint_names = parse_paint_names(params[:paint_names])
    @search_results = {}
    @user_paint_statuses = {}

    # Get all user's paints to check ownership status
    user_paints = current_user.user_paints.includes(:paint).index_by(&:paint_id)

    @paint_names.each do |name|
      next if name.blank?

      # Find top 10 matches for each paint name
      matches = Paint.full_search(name).limit(10).includes(:brand, :product_line)

      if matches.any?
        @search_results[name] = matches

        # Check ownership status for each paint match
        matches.each do |paint|
          if (user_paint = user_paints[paint.id])
            @user_paint_statuses[paint.id] = user_paint.status
          end
        end
      end
    end

    respond_to do |format|
      format.turbo_stream
      format.html { render :bulk_import }
    end
  end

  def destroy
    @user_paint.destroy
    respond_to do |format|
      format.html { redirect_to user_paints_path }
      format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, user_paints_path) }
    end
  end

  private

  def set_user_paint
    @user_paint = current_user.user_paints.find(params[:id])
  end

  def user_paint_params
    params.require(:user_paint).permit(:paint_id, :status, :notes, :purchase_date, :purchase_price)
  end

  def parse_paint_names(text)
    return [] if text.blank?

    # Split by commas, semicolons, or new lines
    text.split(/[,;\r\n]+/).map(&:strip).reject(&:blank?).uniq
  end

  # Apply Ransack filters plus special filters from Filterable concern
  def apply_filters(query)
    # Use the shared filter logic from the Filterable concern
    super
  end
end
