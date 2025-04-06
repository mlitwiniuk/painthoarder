# app/controllers/paints_controller.rb
class PaintsController < ApplicationController
  before_action :authenticate_user!

  def search
    @paints = Paint.joins(:product_line).includes(:product_line)
      .where("paints.name LIKE ? OR paints.code LIKE ?", "%#{params[:query]}%", "%#{params[:query]}%")
      .limit(20)

    # Get IDs of paints the user already has a relationship with
    @user_paint_ids = current_user.user_paints.pluck(:paint_id)

    respond_to do |format|
      format.turbo_stream
    end
  end
end
