module Admin
  class PaintCatalogRunsController < ApplicationController
    before_action :authenticate_user!
    before_action -> { head :forbidden unless current_user.admin? }

    def index
      @sources = PaintCatalog::Sources::CONFIG
      @runs = PaintCatalogRun.order(id: :desc).limit(30)
      @latest_runs = @sources.keys.to_h do |source|
        [source, PaintCatalogRun.where(source: source, auto_apply: true).order(id: :desc).first]
      end
      latest_ready_ids = @sources.keys.filter_map do |source|
        PaintCatalogRun.where(source: source, auto_apply: true, status: "ready").maximum(:id)
      end
      exceptions = PaintCatalogEntry.where(paint_catalog_run_id: latest_ready_ids, status: "pending").where.not(action: "unchanged")
      @exception_count = exceptions.count
      @exceptions = exceptions.includes(:paint_catalog_run).order(:id).limit(50)
    end

    def create
      source = params.require(:source)
      return head :bad_request unless PaintCatalog::Sources::CONFIG.key?(source)
      run = PaintCatalogRun.start!(source)
      begin
        job = PaintCatalogSyncJob.perform_later(run)
        raise ActiveJob::EnqueueError, "Catalog fetch was not queued" unless job
      rescue => error
        run.update!(status: "failed", error_message: "Could not enqueue catalog fetch", finished_at: Time.current)
        Rails.error.report(error, handled: true)
      end
      redirect_to admin_paint_catalog_run_path(run), status: :see_other
    rescue ActiveRecord::RecordNotUnique
      redirect_to admin_paint_catalog_runs_path, alert: I18n.t("paint_catalog.already_active"), status: :see_other
    end

    def show
      @run = PaintCatalogRun.find(params[:id])
      @counts = @run.entries.group(:action).count
      scope = @run.entries.includes(paint: :product_line).order(:id)
      @filter = %w[add link update ambiguous unchanged applied rejected].include?(params[:filter]) ? params[:filter] : "pending"
      scope = if %w[pending applied rejected].include?(@filter)
        scope.where(status: @filter).where.not(action: "unchanged")
      else
        scope.where(action: @filter)
      end
      @pagy, @entries = pagy(scope, limit: 50)
    end

    def cancel
      run = PaintCatalogRun.find(params[:id])
      run.with_lock do
        if %w[queued running].include?(run.status)
          run.update!(status: "failed", error_message: "Cancelled by an administrator; start a new fetch to retry.", finished_at: Time.current)
        end
      end
      redirect_to admin_paint_catalog_run_path(run), status: :see_other
    end

    def apply
      run = PaintCatalogRun.find(params[:id])
      ids = Array(params[:entry_ids]).map(&:to_s).uniq
      raise PaintCatalog::Apply::Conflict, "Select between 1 and 50 comparisons" unless ids.size.between?(1, 50)
      entries = run.entries.where(id: ids).order(:id).to_a
      raise PaintCatalog::Apply::Conflict, "Invalid comparison selection" unless entries.size == ids.size
      PaintCatalogEntry.transaction do
        entries.each do |entry|
          PaintCatalog::Apply.call(entry, reviewer: current_user, acknowledge_warnings: params[:acknowledge_warnings] == "1")
        end
      end
      redirect_to admin_paint_catalog_run_path(run), notice: "Applied #{entries.size} reviewed comparisons.", status: :see_other
    rescue PaintCatalog::Apply::Conflict => error
      redirect_to admin_paint_catalog_run_path(run), alert: error.message, status: :see_other
    end
  end
end
