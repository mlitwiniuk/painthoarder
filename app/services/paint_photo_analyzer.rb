class PaintPhotoAnalyzer
  include HTTParty

  class AnalysisError < StandardError; end

  def initialize(photo)
    @photo = photo
    @llm_config = Rails.application.config_for(:llm)
  rescue RuntimeError
    @llm_config = default_config
  end

  def analyze
    case @llm_config[:provider]
    when "openai"
      analyze_with_openai
    when "anthropic"
      analyze_with_anthropic
    when "google"
      analyze_with_google
    else
      raise AnalysisError, "Unsupported LLM provider: #{@llm_config[:provider]}"
    end
  end

  private

  def default_config
    {
      provider: "openai",
      api_key: ENV["OPENAI_API_KEY"],
      model: "gpt-4o",
      max_tokens: 2000,
      temperature: 0.3
    }
  end

  def photo_base64
    # Handle both ActionDispatch::Http::UploadedFile and ActiveStorage attachments
    @photo_base64 ||= if @photo.respond_to?(:read)
      # It's an uploaded file
      @photo.rewind
      content = @photo.read
      @photo.rewind
      Base64.strict_encode64(content)
    elsif @photo.respond_to?(:download)
      # It's an ActiveStorage attachment
      tempfile = @photo.download
      base64 = Base64.strict_encode64(tempfile.read)
      tempfile.unlink
      base64
    else
      raise AnalysisError, "Invalid photo object"
    end
  end

  def photo_content_type
    if @photo.respond_to?(:content_type)
      @photo.content_type || "image/jpeg"
    else
      "image/jpeg"
    end
  end

  def system_prompt
    <<~PROMPT
      You are an expert at identifying miniature paints from photos. Your task is to analyze the provided image and identify all visible paint bottles/pots.
      
      For each paint you identify, provide:
      - Brand name (e.g., Citadel, Vallejo, Army Painter, etc.)
      - Paint name
      - Paint code (if visible)
      
      Return your response as a JSON array of objects, each containing "brand", "name", and "code" fields.
      If you cannot identify a paint clearly, do not include it in the response.
      Focus only on miniature/hobby paints, not regular art paints.
      
      Example response:
      [
        {"brand": "Citadel", "name": "Abaddon Black", "code": "21-25"},
        {"brand": "Vallejo Model Color", "name": "German Grey", "code": "70.995"}
      ]
    PROMPT
  end

  def analyze_with_openai
    response = self.class.post(
      "https://api.openai.com/v1/chat/completions",
      headers: {
        "Authorization" => "Bearer #{@llm_config[:api_key]}",
        "Content-Type" => "application/json"
      },
      body: {
        model: @llm_config[:model] || "gpt-4o",
        messages: [
          {
            role: "system",
            content: system_prompt
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: "Please identify all the miniature paints visible in this image."
              },
              {
                type: "image_url",
                image_url: {
                  url: "data:#{photo_content_type};base64,#{photo_base64}"
                }
              }
            ]
          }
        ],
        max_tokens: @llm_config[:max_tokens] || 1000,
        temperature: @llm_config[:temperature] || 0.3
      }.to_json
    )

    handle_response(response)
  end

  def analyze_with_anthropic
    response = self.class.post(
      "https://api.anthropic.com/v1/messages",
      headers: {
        "x-api-key" => @llm_config[:api_key],
        "anthropic-version" => "2023-06-01",
        "Content-Type" => "application/json"
      },
      body: {
        model: @llm_config[:model] || "claude-3-5-sonnet-20241022",
        max_tokens: @llm_config[:max_tokens] || 1000,
        temperature: @llm_config[:temperature] || 0.3,
        system: system_prompt,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: "Please identify all the miniature paints visible in this image."
              },
              {
                type: "image",
                source: {
                  type: "base64",
                  media_type: photo_content_type,
                  data: photo_base64
                }
              }
            ]
          }
        ]
      }.to_json
    )

    handle_anthropic_response(response)
  end

  def analyze_with_google
    response = self.class.post(
      "https://generativelanguage.googleapis.com/v1beta/models/#{@llm_config[:model] || "gemini-1.5-flash"}:generateContent",
      headers: {
        "Content-Type" => "application/json"
      },
      query: {
        key: @llm_config[:api_key]
      },
      body: {
        contents: [
          {
            parts: [
              {
                text: "#{system_prompt}\n\nPlease identify all the miniature paints visible in this image."
              },
              {
                inline_data: {
                  mime_type: photo_content_type,
                  data: photo_base64
                }
              }
            ]
          }
        ],
        generationConfig: {
          temperature: @llm_config[:temperature] || 0.3,
          maxOutputTokens: @llm_config[:max_tokens] || 1000
        }
      }.to_json
    )

    handle_google_response(response)
  end

  def handle_response(response)
    if response.success?
      content = response.parsed_response.dig("choices", 0, "message", "content")
      parse_paint_list(content)
    else
      raise AnalysisError, "OpenAI API error: #{response.code} - #{response.body}"
    end
  end

  def handle_anthropic_response(response)
    if response.success?
      content = response.parsed_response.dig("content", 0, "text")
      parse_paint_list(content)
    else
      raise AnalysisError, "Anthropic API error: #{response.code} - #{response.body}"
    end
  end

  def handle_google_response(response)
    if response.success?
      content = response.parsed_response.dig("candidates", 0, "content", "parts", 0, "text")
      parse_paint_list(content)
    else
      raise AnalysisError, "Google API error: #{response.code} - #{response.body}"
    end
  end

  def parse_paint_list(content)
    return [] if content.blank?

    # Extract JSON from the response (it might be wrapped in markdown code blocks)
    json_match = content.match(/\[.*\]/m)
    return [] unless json_match

    begin
      paints = JSON.parse(json_match[0])
      paints.map do |paint|
        # Normalize the paint data
        {
          brand: paint["brand"],
          name: paint["name"],
          code: paint["code"],
          search_string: build_search_string(paint)
        }
      end
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse LLM response: #{e.message}"
      []
    end
  end

  def build_search_string(paint)
    parts = []
    parts << paint["brand"] if paint["brand"].present?
    parts << paint["name"] if paint["name"].present?
    parts << paint["code"] if paint["code"].present?
    parts.join(" ")
  end
end
