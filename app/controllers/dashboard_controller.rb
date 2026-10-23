# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_user!

  RACK_CHECK_LIMIT = 4
  SHOPPING_LIST_LIMIT = 5
  RECENT_LIMIT = 6

  def index
    @check_query = params[:check].to_s.strip
    load_rack_check

    if turbo_frame_request?
      render partial: "dashboard/rack_check", layout: false
      return
    end

    user_paints = current_user.user_paints
    @owned_paints_count = user_paints.owned.count
    @wishlist_count = user_paints.wishlist.count
    @projects_count = current_user.projects.count

    @wishlist_items = user_paints.wishlist.order(created_at: :desc)
      .includes(paint: {product_line: :brand}).limit(SHOPPING_LIST_LIMIT)
    @recent_additions = user_paints.owned.order(created_at: :desc)
      .includes(paint: {product_line: :brand}).limit(RECENT_LIMIT)

    load_latest_project
    load_latest_video
  end

  private

  # "At the shop? Do I own it?" — catalogue matches with the user's status.
  def load_rack_check
    @check_results = []
    return if @check_query.blank?

    paints = Paint.full_search(@check_query).includes(product_line: :brand).limit(50).to_a
    statuses = current_user.user_paints.where(paint_id: paints.map(&:id)).index_by(&:paint_id)
    rank = {"owned" => 0, "wishlist" => 1, "avoid" => 2}
    @check_results = paints
      .map { |paint| [paint, statuses[paint.id]] }
      .sort_by { |paint, user_paint| [rank.fetch(user_paint&.status, 3), paint.name] }
      .first(RACK_CHECK_LIMIT)
  end

  def load_latest_project
    @latest_project = current_user.projects.order(updated_at: :desc).first
    return unless @latest_project

    updates = @latest_project.project_updates
    @latest_project_stats = {
      updates: updates.count,
      photos: ActiveStorage::Attachment.where(record_type: "ProjectUpdate", record_id: updates.select(:id), name: "photos").count,
      paints: PaintUsage.where(project_update_id: updates.select(:id)).distinct.count(:user_paint_id)
    }
    @latest_project_photo = if @latest_project.cover_photo.attached?
      @latest_project.cover_photo
    else
      updates.reorder(created_at: :desc).detect { |update| update.photos.attached? }&.photos&.first
    end
  end

  def load_latest_video
    @latest_video = current_user.videos.completed.recent.first
    return unless @latest_video

    paint_ids = @latest_video.video_paints.matched.distinct.pluck(:paint_id)
    @latest_video_total = paint_ids.size
    @latest_video_owned = current_user.user_paints.owned.where(paint_id: paint_ids).distinct.count(:paint_id)
  end
end
