RubyLLM.configure do |config|
  # Production: ENV (Kamal secrets from 1Password). Development: credentials fallback.
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"].presence || Rails.application.credentials.dig(:llm, :anthropic_api_key)
  config.gemini_api_key = ENV["GEMINI_API_KEY"].presence || Rails.application.credentials.dig(:llm, :gemini_api_key)
  config.default_model = "claude-haiku-4-5"
  config.request_timeout = 120
end
