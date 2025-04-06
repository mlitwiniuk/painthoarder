# app/controllers/user_paints_controller.rb
class UserPaintsController < ApplicationController
  before_action :authenticate_user!
  # before_action :set_user_paint, only: [:update, :destroy]

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

  # Update and destroy actions remain the same...

  private

  def set_user_paint
    @user_paint = current_user.user_paints.find(params[:id])
  end

  def user_paint_params
    params.require(:user_paint).permit(:paint_id, :status, :notes, :purchase_date, :purchase_price)
  end
end
