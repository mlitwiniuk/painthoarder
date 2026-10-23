require "test_helper"
require "digest"

class PaintCatalogWarhubClientTest < ActiveSupport::TestCase
  setup do
    @base = "https://warhub.github.io/warhub-catalog/"
    @data = {schemaVersion: "1.1", kind: "paint-catalog-partition", version: "2026.10.4", gitCommit: "abc123",
             source: {repo: "WarHub/warhub-catalog"}, partition: {type: "brand", key: "vallejo"},
             counts: {paints: 1}, paints: [{id: "vallejo/white"}]}
    @client = PaintCatalog::WarhubClient.new
    @client.stubs(:sleep)
  end

  def stub_catalog(data = @data, **file_overrides)
    body = data.to_json
    file = {path: "paints/by-brand/vallejo.json", records: 1, bytes: body.bytesize, sha256: Digest::SHA256.hexdigest(body)}.merge(file_overrides)
    manifest = {schemaVersion: "1.1", kind: "manifest", version: "2026.10.4", gitCommit: "abc123",
                source: {repo: "WarHub/warhub-catalog"}, files: [file]}
    stub_request(:get, @base + "manifest.json").to_return(body: manifest.to_json)
    stub_request(:get, @base + "paints/by-brand/vallejo.json").to_return(body: body)
  end

  test "fetch validates the manifest checksum and retains release provenance" do
    stub_catalog
    result = @client.fetch("warhub_vallejo")
    assert_equal @data[:paints].as_json, result["paints"]
    assert_equal Digest::SHA256.hexdigest(@data.to_json), result["verified_sha256"]
    assert_equal "2026.10.4", result["version"]
  end

  test "checksum mismatch and incomplete counts fail the entire fetch" do
    stub_catalog(sha256: "wrong")
    assert_raises(PaintCatalog::HttpClient::FetchError) { @client.fetch("warhub_vallejo") }
    stub_catalog(records: 2)
    assert_raises(PaintCatalog::HttpClient::FetchError) { @client.fetch("warhub_vallejo") }
  end

  test "mismatched releases partitions and schemas are refused" do
    [{version: "other"}, {partition: {type: "brand", key: "citadel-colour"}}, {schemaVersion: "2.0"}].each do |change|
      stub_catalog(@data.merge(change))
      assert_raises(PaintCatalog::HttpClient::FetchError) { @client.fetch("warhub_vallejo") }
    end
  end

  test "redirects to arbitrary hosts are never followed" do
    stub_request(:get, @base + "manifest.json").to_return(status: 302, headers: {"Location" => "http://localhost/private"})
    assert_raises(PaintCatalog::HttpClient::FetchError) { @client.fetch("warhub_vallejo") }
    assert_not_requested :get, "http://localhost/private"
  end
end
