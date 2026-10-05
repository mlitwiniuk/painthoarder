module Admin
  class PaintCatalogEntriesController < ApplicationController
    before_action :authenticate_user!
    before_action -> { head :forbidden unless current_user.admin? }
    before_action :set_entry

    def show
      brand = Brand.find_by(name: PaintCatalog::Sources.fetch(@entry.paint_catalog_run.source).fetch(:brand))
      @paints = brand ? brand.paints.includes(:product_line).order(:name) : []
    end

    def update
      if params[:decision] == "reject"
        @entry.with_lock do
          if @entry.status == "pending"
            @entry.update!(status: "rejected", reviewed_by: current_user, reviewed_at: Time.current)
          end
        end
      elsif params[:decision] == "apply"
        PaintCatalog::Apply.call(@entry, reviewer: current_user, paint_id: params[:paint_id],
          create_separate: params[:create_separate] == "1", acknowledge_warnings: params[:acknowledge_warnings] == "1")
      else
        return head :bad_request
      end
      redirect_to admin_paint_catalog_run_path(@entry.paint_catalog_run), status: :see_other
    rescue PaintCatalog::Apply::Conflict, ActiveRecord::RecordNotFound => error
      redirect_to admin_paint_catalog_entry_path(@entry), alert: error.message, status: :see_other
    end

    private

    def set_entry
      @entry = PaintCatalogEntry.find(params[:id])
    end
  end
end
