require "test_helper"

class PaintCatalogShopifyClientTest < ActiveSupport::TestCase
  setup do
    @client = PaintCatalog::ShopifyClient.new
    @client.stubs(:sleep)
    @url = "https://monumenthobbies.com/collections/paint-singles/products.json"
  end

  test "fetch follows pagination until the complete final page" do
    first = 250.times.map { |id| {id: id} }
    stub_request(:get, @url).with(query: {limit: 250, page: 1}).to_return(body: {products: first}.to_json)
    stub_request(:get, @url).with(query: {limit: 250, page: 2}).to_return(body: {products: [{id: 251}]}.to_json)
    assert_equal 251, @client.fetch("monument").size
  end

  test "a repeated page fails rather than treating a partial catalog as complete" do
    batch = 250.times.map { |id| {id: id} }
    stub_request(:get, @url).with(query: hash_including(limit: "250")).to_return(body: {products: batch}.to_json)
    assert_raises(PaintCatalog::ShopifyClient::FetchError) { @client.fetch("monument") }
  end

  test "redirects are not followed and rate limits have bounded retries" do
    stub = stub_request(:get, @url).with(query: {limit: 250, page: 1})
      .to_return(status: 429, headers: {"Retry-After" => "1"}).then.to_return(body: {products: []}.to_json)
    assert_equal [], @client.fetch("monument")
    assert_requested stub, times: 2
    reset_executed_requests!
    stub_request(:get, @url).with(query: {limit: 250, page: 1}).to_return(status: 302, headers: {"Location" => "http://localhost/private"})
    assert_raises(PaintCatalog::ShopifyClient::FetchError) { @client.fetch("monument") }
  end
end
