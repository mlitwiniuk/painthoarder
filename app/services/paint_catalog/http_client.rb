require "net/http"

module PaintCatalog
  class HttpClient
    class FetchError < StandardError; end
    class RetryRequest < StandardError; end
    MAX_RESPONSE_BYTES = 5.megabytes

    private

    def get_json(uri)
      JSON.parse(get_body(uri))
    end

    def get_body(uri)
      attempts = 0
      begin
        attempts += 1
        body = +""
        response = nil
        Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
          request = Net::HTTP::Get.new(uri, {"User-Agent" => "PaintHoarder catalog sync/1.0", "Accept" => "application/json"})
          http.request(request) do |res|
            response = res
            res.read_body do |chunk|
              body << chunk
              raise FetchError, "Producer response exceeded size limit" if body.bytesize > MAX_RESPONSE_BYTES
            end
          end
        end
        if response.code == "429" || response.code.to_i >= 500
          if attempts < 3
            sleep response["Retry-After"].to_i.clamp(attempts * 2, 30)
            raise RetryRequest
          end
        end
        raise FetchError, "Producer returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
        body
      rescue RetryRequest
        retry
      end
    end
  end
end
