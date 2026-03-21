class DirectoryPaintsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :redirect_to_nearest_parent

  def show
    @brand = Brand.friendly.find(params[:brand_id])
    @product_line = @brand.product_lines.friendly.find(params[:product_line_id])
    @paint = @product_line.paints.friendly.find(params[:id])

    if user_signed_in?
      existing = current_user.user_paints.find_by(paint_id: @paint.id)
      @user_paint = existing || UserPaint.new(paint: @paint, user: current_user, virtual: true)
    else
      @user_paint = UserPaint.new(paint: @paint, virtual: true)
    end
  end

  private

  def redirect_to_nearest_parent
    brand = Brand.friendly.find(params[:brand_id]) rescue nil
    product_line = brand&.product_lines&.friendly&.find(params[:product_line_id]) rescue nil

    if product_line
      redirect_to brand_product_line_path(brand, product_line), status: :moved_permanently
    elsif brand
      redirect_to brand_path(brand), status: :moved_permanently
    else
      redirect_to brands_path, status: :moved_permanently
    end
  end
end
