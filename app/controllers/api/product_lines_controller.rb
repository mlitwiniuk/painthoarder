module Api
  class ProductLinesController < ApplicationController
    before_action :authenticate_user!

    def index
      @product_lines = ProductLine.order(:name)

      @product_lines = @product_lines.where(brand_id: params[:brand_id]) if params[:brand_id].present?

      if params[:query].present?
        @product_lines = @product_lines.where("name LIKE ?", "%#{params[:query]}%")
      end

      render json: @product_lines.map { |pl| { id: pl.id, text: pl.name, brand_id: pl.brand_id } }
    end
  end
end
