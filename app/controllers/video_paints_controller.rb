class VideoPaintsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_video_and_paint

  def edit
  end

  def update
    paint_id = params.dig(:video_paint, :paint_id)

    if paint_id.present?
      paint = Paint.find(paint_id)
      @video_paint.update!(paint: paint)
    else
      @video_paint.update!(paint: nil)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          @video_paint,
          partial: "videos/video_paint",
          locals: { video_paint: @video_paint.reload, video: @video, alternatives: nil }
        )
      end
      format.html { redirect_to video_path(@video) }
    end
  end

  private

  def set_video_and_paint
    @video = Video.friendly.find(params[:video_id])
    @video_paint = @video.video_paints.find(params[:id])

    unless current_user == @video.user
      redirect_to video_path(@video), alert: "You don't have permission to perform this action."
    end
  end
end
