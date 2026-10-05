require "net/http"

module PaintCatalog
  # Fixed producer hosts only. Redirects, oversized responses, and incomplete
  # pagination fail the entire fetch; they never produce an applicable batch.
  class ShopifyClient
    class FetchError < StandardError; end
    PAGE_SIZE = 250
    MAX_PAGES = 20
    MAX_PAGE_BYTES = 5.megabytes

    def fetch(source)
      config = Sources.fetch(source)
      products = []
      seen = Set.new
      (1..MAX_PAGES).each do |page|
        sleep 0.5 if page > 1
        uri = URI::HTTPS.build(host: config.fetch(:host), path: config.fetch(:path),
          query: URI.encode_www_form(limit: PAGE_SIZE, page: page))
        data = get_json(uri)
        raise FetchError, "Invalid response envelope" unless data.is_a?(Hash)
        batch = data.fetch("products")
        raise FetchError, "Invalid products response" unless batch.is_a?(Array)
        batch.each do |product|
          raise FetchError, "Invalid product record" unless product.is_a?(Hash)
          id = product.fetch("id").to_s
          raise FetchError, "Repeated product during pagination; retry the fetch" unless seen.add?(id)
        end
        products.concat(batch)
        return products if batch.length < PAGE_SIZE
      end
      raise FetchError, "Pagination limit reached; no changes can be applied"
    rescue KeyError, JSON::ParserError => e
      raise FetchError, "Producer response format changed (#{e.class})"
    end

    private

    def get_json(uri)
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
              raise FetchError, "Producer response exceeded size limit" if body.bytesize > MAX_PAGE_BYTES
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
        JSON.parse(body)
      rescue RetryRequest
        retry
      end
    end

    class RetryRequest < StandardError; end
  end
end
