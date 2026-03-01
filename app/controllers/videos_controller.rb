class VideosController < ApplicationController
  before_action :authenticate_user!, except: %i[public_index show alternatives]
  before_action :set_video, only: %i[show destroy alternatives]
  before_action :ensure_owner, only: %i[destroy]

  # GET /videos/public
  def public_index
    @pagy, @videos = pagy(
      Video.completed.recent.includes(:user, :video_paints),
      items: 12
    )
  end

  # GET /videos
  def index
    @pagy, @videos = pagy(
      current_user.videos.recent.includes(:video_paints),
      items: 12
    )
  end

  # GET /videos/:id
  def show
    # Public access for completed videos, owner can see all statuses
    unless @video.completed? || (user_signed_in? && current_user == @video.user)
      redirect_to public_videos_path, alert: "This video is still being processed."
      return
    end

    @video_paints = @video.video_paints.includes(:paint).order(:created_at)

    if user_signed_in?
      paint_ids = @video_paints.where.not(paint_id: nil).pluck(:paint_id)
      @current_user_paints = current_user.user_paints
        .where(paint_id: paint_ids)
        .index_by(&:paint_id)
    end
  end

  # GET /videos/new
  def new
  end

  # POST /videos
  def create
    unless current_user.can_create_video?
      period = User.video_limit_period
      redirect_to new_video_path, alert: "You've reached your video analysis limit (#{current_user.video_limit} per #{period}). Contact an admin to increase it."
      return
    end

    url = params[:url]&.strip
    youtube_video_id = Video.extract_video_id(url)

    if youtube_video_id.blank?
      flash.now[:alert] = "Please enter a valid YouTube URL."
      render :new, status: :unprocessable_entity
      return
    end

    # Check for existing video
    existing = Video.find_by(youtube_video_id: youtube_video_id)
    if existing
      redirect_to video_path(existing), notice: "This video has already been analyzed."
      return
    end

    # Fetch oEmbed metadata
    metadata = fetch_oembed_metadata(youtube_video_id)

    @video = current_user.videos.build(
      youtube_video_id: youtube_video_id,
      title: metadata[:title] || "YouTube Video",
      author_name: metadata[:author_name],
      thumbnail_url: "https://img.youtube.com/vi/#{youtube_video_id}/maxresdefault.jpg",
      status: :pending
    )

    if @video.save
      VideoAnalysisJob.perform_later(@video.id)
      redirect_to video_path(@video), notice: "Video submitted for analysis. Results will appear shortly."
    else
      flash.now[:alert] = "Could not save the video. Please try again."
      render :new, status: :unprocessable_entity
    end
  end

  # GET /videos/:id/alternatives/:brand_slug
  def alternatives
    unless @video.completed? || (user_signed_in? && current_user == @video.user)
      redirect_to public_videos_path, alert: "This video is still being processed."
      return
    end

    matched_video_paints = @video.video_paints.matched.includes(paint: {product_line: :brand})
    @brand = Brand.friendly.find(params[:brand_slug])

    if params[:brand_slug] != @brand.slug
      redirect_to alternatives_video_path(@video, brand_slug: @brand.slug), status: :moved_permanently
      return
    end

    brand_paints = @brand.paints.includes(product_line: :brand)

    # Preload similarity map for all source product lines
    source_pl_ids = matched_video_paints.filter_map { |vp| vp.paint&.product_line_id }.uniq
    similar_pl_ids_by_pl = ProductLineSimilarity
      .where(product_line_id: source_pl_ids)
      .pluck(:product_line_id, :similar_product_line_id)
      .group_by(&:first)
      .transform_values { |pairs| pairs.map(&:last).to_set }

    @alternatives = {}
    matched_video_paints.each do |vp|
      source = vp.paint
      similar_pls = similar_pl_ids_by_pl[source.product_line_id] || Set.new

      # Partition: similar-line paints vs rest
      similar_line, rest = brand_paints.partition { |bp| similar_pls.include?(bp.product_line_id) }

      rgb_distance = ->(bp) { (source.red - bp.red)**2 + (source.green - bp.green)**2 + (source.blue - bp.blue)**2 }

      # Fill top 3: similar-line first (by RGB distance), then remainder
      candidates = similar_line.sort_by(&rgb_distance)
      if candidates.size < 3
        candidates += rest.sort_by(&rgb_distance).first(3 - candidates.size)
      end

      @alternatives[vp.id] = candidates.first(3)
    end

    @video_paints = @video.video_paints.includes(paint: {product_line: :brand}).order(:created_at)

    if user_signed_in?
      paint_ids = @video_paints.where.not(paint_id: nil).pluck(:paint_id)
      @current_user_paints = current_user.user_paints
        .where(paint_id: paint_ids)
        .index_by(&:paint_id)
    end

    render :show
  end

  # DELETE /videos/:id
  def destroy
    @video.destroy!
    redirect_to videos_path, status: :see_other, notice: "Video was successfully deleted."
  end

  private

  def set_video
    @video = Video.friendly.find(params[:id])
    redirect_to_canonical_slug(@video, params[:id])
  end

  def redirect_to_canonical_slug(record, param)
    if param != record.slug
      # Redirect to canonical slug URL, preserving the rest of the path
      if params[:brand_slug]
        redirect_to alternatives_video_path(record, brand_slug: params[:brand_slug]), status: :moved_permanently
      else
        redirect_to video_path(record), status: :moved_permanently
      end
    end
  end

  def ensure_owner
    unless current_user == @video.user
      redirect_to videos_path, alert: "You don't have permission to perform this action."
    end
  end

  def fetch_oembed_metadata(video_id)
    uri = URI("https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=#{video_id}&format=json")
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      {title: data["title"], author_name: data["author_name"]}
    else
      {title: nil, author_name: nil}
    end
  rescue => e
    Rails.logger.warn("Failed to fetch oEmbed for #{video_id}: #{e.message}")
    {title: nil, author_name: nil}
  end
end
