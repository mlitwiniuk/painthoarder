class BrandsController < ApplicationController
  def index
    @brands = Brand.left_joins(:product_lines, :paints)
      .select("brands.*, COUNT(DISTINCT product_lines.id) AS product_lines_count, COUNT(DISTINCT paints.id) AS paints_count")
      .group("brands.id")
      .order(:name)
  end

  def show
    @brand = Brand.friendly.find(params[:id])
    @product_lines = @brand.product_lines
      .left_joins(:paints)
      .select("product_lines.*, COUNT(paints.id) AS paints_count")
      .group("product_lines.id")
      .order(:name)
  end
end
