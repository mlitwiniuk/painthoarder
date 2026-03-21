class ProductLinesController < ApplicationController
  include Filterable
  rescue_from ActiveRecord::RecordNotFound, with: :redirect_to_nearest_parent

  def show
    @brand = Brand.friendly.find(params[:brand_id])
    @product_line = @brand.product_lines.friendly.find(params[:id])
    @q = @product_line.paints.includes(product_line: :brand).ransack(params[:q])

    @query = apply_filters(@q.result).order(name: :asc)
    @pagy, @paints = pagy(@query, items: 24)

    @color_categories = ColorCategorization::COLOR_CATEGORIES
  end

  private

  def redirect_to_nearest_parent
    brand = Brand.friendly.find(params[:brand_id]) rescue nil

    if brand
      redirect_to brand_path(brand), status: :moved_permanently
    else
      redirect_to brands_path, status: :moved_permanently
    end
  end
end
