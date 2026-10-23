require "net/http"

module PaintCatalog
  # Fixed producer hosts only. Redirects, oversized responses, and incomplete
  # pagination fail the entire fetch; they never produce an applicable batch.
  class ShopifyClient < HttpClient
    PAGE_SIZE = 250
    MAX_PAGES = 20

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
  end
end
