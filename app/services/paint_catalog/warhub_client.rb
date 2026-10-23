require "digest"

module PaintCatalog
  class WarhubClient < HttpClient
    HOST = "warhub.github.io"
    ROOT = "/warhub-catalog/"

    def fetch(source)
      partition = Sources.fetch(source).fetch(:partition)
      path = "paints/by-brand/#{partition}.json"
      manifest = get_json(uri("manifest.json"))
      validate_envelope!(manifest, "manifest")
      file = manifest.fetch("files").find { |entry| entry["path"] == path }
      raise FetchError, "WarHub partition is missing from the manifest" unless file
      body = get_body(uri(path))
      unless file["bytes"] == body.bytesize && file["sha256"] == Digest::SHA256.hexdigest(body)
        raise FetchError, "WarHub checksum/size mismatch; release may be changing, retry later"
      end
      data = JSON.parse(body)
      validate_envelope!(data, "paint-catalog-partition")
      unless data.fetch("partition").values_at("type", "key") == ["brand", partition] &&
          data.values_at("version", "gitCommit") == manifest.values_at("version", "gitCommit")
        raise FetchError, "WarHub partition or release mismatch"
      end
      paints = data.fetch("paints")
      unless paints.is_a?(Array) && paints.size == data.fetch("counts")["paints"] && paints.size == file["records"]
        raise FetchError, "WarHub paint count mismatch"
      end
      data.merge("verified_sha256" => file.fetch("sha256"))
    rescue KeyError, TypeError, JSON::ParserError => error
      raise FetchError, "WarHub response format changed (#{error.class})"
    end

    private

    def uri(path)
      URI::HTTPS.build(host: HOST, path: ROOT + path)
    end

    def validate_envelope!(data, kind)
      unless data.is_a?(Hash) && data["schemaVersion"] == "1.1" && data["kind"] == kind &&
          data.dig("source", "repo") == "WarHub/warhub-catalog" && data["version"].is_a?(String) && data["gitCommit"].is_a?(String)
        raise FetchError, "Unsupported WarHub schema or source"
      end
    end
  end
end
