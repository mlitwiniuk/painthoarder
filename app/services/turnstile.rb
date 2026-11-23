# frozen_string_literal: true

require "net/http"

# Cloudflare Turnstile server-side verification.
# https://developers.cloudflare.com/turnstile/get-started/server-side-validation/
#
# Keys come from credentials (turnstile.site_key / turnstile.secret_key) or ENV
# (TURNSTILE_SITE_KEY / TURNSTILE_SECRET_KEY). Outside production, Cloudflare's
# "always passes" test keys are used when none are configured.
#
# Verification fails closed: a missing token, missing secret, network error or
# malformed response all reject the request.
module Turnstile
  VERIFY_URL = URI("https://challenges.cloudflare.com/turnstile/v0/siteverify")
  RESPONSE_PARAM = "cf-turnstile-response"
  TIMEOUT = 5 # seconds
  MAX_TOKEN_LENGTH = 2048 # documented maximum

  # https://developers.cloudflare.com/turnstile/troubleshooting/testing/
  TEST_SITE_KEY = "1x00000000000000000000AA"
  TEST_SECRET_KEY = "1x0000000000000000000000000000000AA"

  module_function

  def site_key
    ENV["TURNSTILE_SITE_KEY"].presence ||
      Rails.application.credentials.dig(:turnstile, :site_key).presence ||
      (TEST_SITE_KEY unless Rails.env.production?)
  end

  def secret_key
    ENV["TURNSTILE_SECRET_KEY"].presence ||
      Rails.application.credentials.dig(:turnstile, :secret_key).presence ||
      (TEST_SECRET_KEY unless Rails.env.production?)
  end

  def configured?
    site_key.present? && secret_key.present?
  end

  # Returns true only when Cloudflare confirms the token.
  def verify(token, remote_ip: nil)
    token = token.to_s
    return false if token.blank? || token.length > MAX_TOKEN_LENGTH

    secret = secret_key
    if secret.blank?
      Rails.logger.error("[Turnstile] secret key not configured; rejecting request")
      return false
    end

    params = {secret: secret, response: token, remoteip: remote_ip}.compact
    response = post(params)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("[Turnstile] siteverify HTTP #{response.code}")
      return false
    end

    result = JSON.parse(response.body)
    Rails.logger.info("[Turnstile] rejected: #{Array(result["error-codes"]).join(",")}") unless result["success"] == true
    result["success"] == true
  rescue JSON::ParserError, Timeout::Error, SystemCallError, SocketError, OpenSSL::SSL::SSLError, Net::HTTPBadResponse => e
    Rails.logger.warn("[Turnstile] siteverify failed: #{e.class}")
    false
  end

  def post(params)
    Net::HTTP.start(VERIFY_URL.host, VERIFY_URL.port, use_ssl: true,
      open_timeout: TIMEOUT, read_timeout: TIMEOUT, write_timeout: TIMEOUT) do |http|
      request = Net::HTTP::Post.new(VERIFY_URL)
      request.set_form_data(params)
      http.request(request)
    end
  end
  private_class_method :post
end
