module Api
  class BrandsController < ApplicationController
    before_action :authenticate_user!

    def index
      @brands = Brand.order(:name)

      if params[:query].present?
        @brands = @brands.where("name LIKE ?", "%#{params[:query]}%")
      end

      render json: @brands.map { |brand| {id: brand.id, text: brand.name} }
    end
  end
end
