class PaintPhotoAnalyzer
  class AnalysisError < StandardError; end

  class PaintIdentifier < RubyLLM::Tool
    description "Submit the list of identified miniature paints from the photo"

    params do
      array :paints, description: "List of identified paints" do
        object do
          string :brand, description: "Paint brand name (e.g., Citadel, Vallejo, Army Painter)"
          string :name, description: "Paint name"
          string :code, description: "Paint code if visible, empty string if not", required: false
        end
      end
    end

    attr_reader :identified_paints

    def execute(paints:)
      @identified_paints = paints
      halt "Paints identified"
    end
  end

  def initialize(photo)
    @photo = photo
  end

  def analyze
    tempfile = write_photo_to_tempfile
    tool = PaintIdentifier.new

    chat = RubyLLM.chat
      .with_temperature(0.3)
      .with_instructions(system_prompt)
      .with_tool(tool)

    chat.ask(
      "Please identify all the miniature paints visible in this image and submit them using the paint identifier tool.",
      with: tempfile.path
    )

    paints = tool.identified_paints || []
    paints.map do |paint|
      paint = paint.stringify_keys if paint.respond_to?(:stringify_keys)
      {
        brand: paint["brand"],
        name: paint["name"],
        code: paint["code"],
        search_string: build_search_string(paint)
      }
    end
  rescue RubyLLM::Error => e
    raise AnalysisError, "LLM analysis failed: #{e.message}"
  ensure
    tempfile&.close!
  end

  private

  def write_photo_to_tempfile
    extension = content_type_to_extension
    tempfile = Tempfile.new(["paint_photo", extension])
    tempfile.binmode

    if @photo.respond_to?(:read)
      @photo.rewind
      tempfile.write(@photo.read)
      @photo.rewind
    elsif @photo.respond_to?(:download)
      tempfile.write(@photo.download)
    else
      raise AnalysisError, "Invalid photo object"
    end

    tempfile.flush
    tempfile
  end

  def content_type_to_extension
    case @photo.respond_to?(:content_type) && @photo.content_type
    when "image/png" then ".png"
    when "image/webp" then ".webp"
    when "image/gif" then ".gif"
    else ".jpg"
    end
  end

  def system_prompt
    <<~PROMPT
      You are an expert at identifying miniature paints from photos. Your task is to analyze the provided image and identify all visible paint bottles/pots.

      For each paint you identify, provide:
      - Brand name (e.g., Citadel, Vallejo, Army Painter, etc.)
      - Paint name
      - Paint code (if visible)

      If you cannot identify a paint clearly, do not include it.
      Focus only on miniature/hobby paints, not regular art paints.
      Always use the paint identifier tool to submit your findings.
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
