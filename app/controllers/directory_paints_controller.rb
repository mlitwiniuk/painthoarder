class DirectoryPaintsController < ApplicationController
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
end
