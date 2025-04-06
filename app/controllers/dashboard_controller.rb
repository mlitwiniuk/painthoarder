# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_user!

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
      .group_by { |up| color_category(up.paint) }
      .transform_values(&:count)
      .sort_by { |_, count| -count }
      .to_h

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  def color_category(paint)
    # Simple color categorization - can be refined
    r, g, b = paint.red, paint.green, paint.blue

    if r > 200 && g < 100 && b < 100
      "Reds"
    elsif r < 100 && g > 200 && b < 100
      "Greens"
    elsif r < 100 && g < 100 && b > 200
      "Blues"
    elsif r > 200 && g > 200 && b < 100
      "Yellows"
    elsif r > 200 && g < 100 && b > 200
      "Purples"
    elsif r < 100 && g > 200 && b > 200
      "Cyans"
    elsif r > 180 && g > 180 && b > 180
      "Whites"
    elsif r < 50 && g < 50 && b < 50
      "Blacks"
    elsif (r - g).abs < 30 && (g - b).abs < 30 && (r - b).abs < 30
      "Grays"
    else
      "Other"
    end
  end
end
