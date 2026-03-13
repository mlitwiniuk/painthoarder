class ProductLinesController < ApplicationController
  include Filterable

  def show
    @brand = Brand.friendly.find(params[:brand_id])
    @product_line = @brand.product_lines.friendly.find(params[:id])
    @q = @product_line.paints.includes(product_line: :brand).ransack(params[:q])

    @query = apply_filters(@q.result).order(name: :asc)
    @pagy, @paints = pagy(@query, items: 24)

    @color_categories = ColorCategorization::COLOR_CATEGORIES
  end
end
