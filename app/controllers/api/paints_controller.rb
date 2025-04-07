module Api
  class PaintsController < ApplicationController
    before_action :authenticate_user!

    def index
      @paints = Paint.includes(:product_line).order(:name)

      if params[:product_line_id].present?
        @paints = @paints.where(product_line_id: params[:product_line_id])
      end

      if params[:query].present?
        @paints = @paints.where("paints.name LIKE ? OR paints.code LIKE ?", "%#{params[:query]}%", "%#{params[:query]}%")
      end

      render json: @paints.map { |paint|
        {
          id: paint.id,
          text: "#{paint.name} (#{paint.code})",
          color: paint.hex_color,
          product_line_id: paint.product_line_id
        }
      }
    end

    def show
      @paint = Paint.includes(:brand, :product_line).find(params[:id])
      render json: {
        id: @paint.id,
        name: @paint.name,
        code: @paint.code,
        color: @paint.hex_color,
        brand_name: @paint.brand&.name,
        product_line_name: @paint.product_line&.name
      }
    end
  end
end
