class VideoAnalyzer
  class AnalysisError < StandardError; end

  class PaintListSchema < RubyLLM::Schema
    description "List of miniature paints identified from a YouTube video"

    array :paints, description: "List of identified paints used in the video" do
      object do
        string :brand, description: "Paint brand name (e.g., Citadel, Vallejo, Army Painter)"
        string :name, description: "Paint name"
        string :code, description: "Paint code if mentioned, empty string if not", required: false
        string :paint_type, description: "Type of paint (e.g., base, layer, wash, contrast, shade, technical, primer)", required: false
        string :hex_color, description: "Estimated hex color of the paint (e.g., '#FF0000' for red), based on what you see or know about this paint", required: false
        string :product_line_name, description: "Product line or range name (e.g., 'Base', 'Layer', 'Model Color', 'Speedpaint')", required: false
        string :timestamp, description: "Approximate timestamp in video where paint is mentioned (e.g., '2:30'), empty if unknown", required: false
        string :context, description: "How the paint is used (e.g., 'base coat for skin', 'edge highlight on armor')", required: false
      end
    end
  end

  def initialize(video)
    @video = video
  end

  def analyze
    transcript = fetch_transcript
    response = transcript ? analyze_transcript(transcript) : analyze_video
    parse_response(response)
  rescue RubyLLM::Error => e
    raise AnalysisError, "LLM analysis failed: #{e.message}"
  end

  private

  def fetch_transcript
    api = YoutubeRb::Transcript::YouTubeTranscriptApi.new
    fetched = api.fetch(@video.youtube_video_id, languages: ["en"])

    lines = fetched.map do |snippet|
      total_seconds = snippet.start.to_i
      minutes = total_seconds / 60
      seconds = total_seconds % 60
      "[#{minutes}:#{format("%02d", seconds)}] #{snippet.text}"
    end

    text = lines.join("\n")
    Rails.logger.info("[VideoAnalyzer] Using transcript for video #{@video.youtube_video_id} (#{text.length} chars)")
    text
  rescue => e
    Rails.logger.info("[VideoAnalyzer] Transcript unavailable for video #{@video.youtube_video_id}: #{e.class} - #{e.message}. Falling back to video analysis.")
    nil
  end

  def analyze_transcript(transcript)
    chat = RubyLLM.chat(model: "gemini-2.5-flash")
      .with_temperature(0.3)
      .with_instructions(transcript_system_prompt)
      .with_schema(PaintListSchema)

    chat.ask(transcript)
  end

  def analyze_video
    Rails.logger.info("[VideoAnalyzer] Using low-res video analysis for video #{@video.youtube_video_id}")

    content = RubyLLM::Content::Raw.new([
      {
        fileData: {
          mimeType: "video/youtube",
          fileUri: @video.youtube_url
        }
      },
      {
        text: "Please identify all the miniature paints mentioned or shown in this YouTube video."
      }
    ])

    chat = RubyLLM.chat(model: "gemini-2.5-flash")
      .with_temperature(0.3)
      .with_instructions(video_system_prompt)
      .with_schema(PaintListSchema)
      .with_params(generationConfig: {mediaResolution: "MEDIA_RESOLUTION_LOW"})

    chat.ask(content)
  end

  def parse_response(response)
    paints = response.content&.dig("paints") || []

    paints.map do |paint|
      {
        brand: paint["brand"],
        name: paint["name"],
        code: paint["code"],
        paint_type: paint["paint_type"],
        hex_color: paint["hex_color"],
        product_line_name: paint["product_line_name"],
        timestamp: paint["timestamp"],
        context: paint["context"],
        search_string: build_search_string(paint)
      }
    end
  end

  def paint_identification_instructions
    <<~PROMPT
      For each paint you identify, provide:
      - Brand name (e.g., Citadel, Vallejo, Army Painter, Scale75, AK Interactive, etc.)
      - Paint name (exact name as stated)
      - Paint code (if mentioned or visible)
      - Paint type (base, layer, wash, contrast, shade, technical, primer, etc.)
      - Estimated hex color (e.g., "#1A1A1A" for a black paint) — use your knowledge of the paint or visual cues
      - Product line or range name (e.g., "Base", "Layer", "Model Color", "Speedpaint")
      - Approximate timestamp where the paint is first mentioned or shown
      - Context of how the paint is used (e.g., "base coat for skin", "edge highlight on armor")

      Focus only on miniature/hobby paints. Do not include regular art supplies, primers from hardware stores, or non-paint products.
      If a paint is mentioned multiple times, include it only once with the earliest timestamp.
    PROMPT
  end

  def transcript_system_prompt
    <<~PROMPT
      You are an expert at identifying miniature paints from YouTube painting tutorial transcripts.
      Your task is to analyze the provided transcript text and identify all miniature/hobby paints mentioned.

      #{paint_identification_instructions}
    PROMPT
  end

  def video_system_prompt
    <<~PROMPT
      You are an expert at identifying miniature paints from YouTube painting tutorials.
      Your task is to watch the provided video and identify all miniature/hobby paints mentioned, shown, or used.

      #{paint_identification_instructions}
    PROMPT
  end

  def build_search_string(paint)
    parts = []
    parts << paint["brand"] if paint["brand"].present?
    parts << paint["name"] if paint["name"].present?
    parts << paint["code"] if paint["code"].present?
    parts.join(" ")
  end
end
