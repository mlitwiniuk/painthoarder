class VideoAnalysisJob < ApplicationJob
  queue_as :default
  retry_on VideoAnalyzer::AnalysisError, wait: :polynomially_longer, attempts: 3

  def perform(video_id)
    video = Video.find(video_id)
    return if video.completed?

    update_status(video, :processing)

    analyzer = VideoAnalyzer.new(video)
    results = analyzer.analyze

    video.raw_response = results.to_json

    results.each do |result|
      paint = match_paint(result[:search_string], result[:brand], result[:name], result[:code])

      video.video_paints.create!(
        paint: paint,
        brand_name: result[:brand],
        paint_name: result[:name],
        paint_code: result[:code],
        paint_type: result[:paint_type],
        hex_color: paint&.hex_color || result[:hex_color],
        product_line_name: paint&.product_line&.name || result[:product_line_name],
        timestamp: result[:timestamp],
        context: result[:context]
      )
    end

    update_status(video, :completed, processed_at: Time.current)
  rescue VideoAnalyzer::AnalysisError => e
    update_status(video, :failed, error_message: e.message)
    raise # re-raise for retry_on
  rescue => e
    update_status(video, :failed, error_message: "Unexpected error: #{e.message}")
    Rails.logger.error("VideoAnalysisJob failed for video #{video_id}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
  end

  private

  def match_paint(search_string, brand, name, code)
    # Try full search string first (brand + name + code)
    results = Paint.full_search(search_string)
    return results.first if results.any?

    # Try brand + name
    if brand.present? && name.present?
      results = Paint.full_search("#{brand} #{name}")
      return results.first if results.any?
    end

    # Try just name
    if name.present?
      results = Paint.full_search(name)
      return results.first if results.any?
    end

    # Try code
    if code.present?
      results = Paint.full_search(code)
      return results.first if results.any?
    end

    nil
  end

  def update_status(video, status, **attrs)
    video.update!(status: status, **attrs)
    broadcast_results(video)
  end

  def broadcast_results(video)
    Turbo::StreamsChannel.broadcast_replace_to(
      video,
      target: "video_results",
      partial: "videos/results",
      locals: {video: video}
    )
  rescue => e
    Rails.logger.error("[VideoAnalysisJob] Broadcast failed for video #{video.id}: #{e.class} - #{e.message}")
  end
end
