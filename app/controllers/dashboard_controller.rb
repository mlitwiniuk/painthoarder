# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_user!
  include ColorCategorization

  def index
    @owned_paints_count = current_user.user_paints.owned.count
    @wishlist_count = current_user.user_paints.wishlist.count
    @avoid_count = current_user.user_paints.avoid.count

    # Recent additions (last 10)
    @recent_additions = current_user.user_paints.owned.order(created_at: :desc).limit(10).includes(paint: :product_line)

    # Wishlist items
    @wishlist_items = current_user.user_paints.wishlist.includes(paint: :product_line)

    # Get color stats
    @color_distribution = current_user.user_paints.owned.includes(:paint)
      .group_by { |up| ColorCategorization.categorize(up.paint) }
      .transform_values(&:count)
      .sort_by { |_, count| -count }
      .to_h

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  # Color categorization is now handled by the ColorCategorization module
end
