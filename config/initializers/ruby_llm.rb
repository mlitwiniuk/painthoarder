RubyLLM.configure do |config|
  config.anthropic_api_key = Rails.application.credentials.dig(:llm, :anthropic_api_key)
  config.default_model = "claude-haiku-4-5"
  config.request_timeout = 120
end
