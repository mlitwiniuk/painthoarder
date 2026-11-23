require "test_helper"

class TurnstileTest < ActiveSupport::TestCase
  URL = Turnstile::VERIFY_URL.to_s

  def stub_verify(body, status: 200)
    stub_request(:post, URL).to_return(status: status, body: body.to_json, headers: {"Content-Type" => "application/json"})
  end

  test "accepts a token Cloudflare confirms and forwards secret, token and IP" do
    stub_verify({success: true})
    assert Turnstile.verify("tok", remote_ip: "203.0.113.5")
    assert_requested :post, URL, body: {secret: Turnstile.secret_key, response: "tok", remoteip: "203.0.113.5"}
  end

  test "rejects a token Cloudflare refuses" do
    stub_verify({:success => false, "error-codes" => ["invalid-input-response"]})
    assert_not Turnstile.verify("tok")
  end

  test "rejects blank or oversized tokens without calling Cloudflare" do
    assert_not Turnstile.verify(nil)
    assert_not Turnstile.verify("")
    assert_not Turnstile.verify("x" * (Turnstile::MAX_TOKEN_LENGTH + 1))
    assert_not_requested :post, URL
  end

  test "fails closed on HTTP errors, timeouts and garbage" do
    stub_verify({success: true}, status: 500)
    assert_not Turnstile.verify("tok")

    stub_request(:post, URL).to_timeout
    assert_not Turnstile.verify("tok")

    stub_request(:post, URL).to_return(status: 200, body: "<html>")
    assert_not Turnstile.verify("tok")

    stub_verify({success: "true"})
    assert_not Turnstile.verify("tok")
  end

  test "fails closed when no secret is configured" do
    Turnstile.stubs(:secret_key).returns(nil)
    assert_not Turnstile.verify("tok")
    assert_not_requested :post, URL
  end

  test "has no test-key fallback in production" do
    Rails.stubs(:env).returns(ActiveSupport::EnvironmentInquirer.new("production"))
    Rails.application.credentials.stubs(:dig).returns(nil)
    with_env("TURNSTILE_SITE_KEY" => nil, "TURNSTILE_SECRET_KEY" => nil) do
      assert_nil Turnstile.site_key
      assert_nil Turnstile.secret_key
      assert_not Turnstile.configured?
    end
  end

  test "ENV keys take precedence" do
    with_env("TURNSTILE_SITE_KEY" => "site", "TURNSTILE_SECRET_KEY" => "secret") do
      assert_equal "site", Turnstile.site_key
      assert_equal "secret", Turnstile.secret_key
    end
  end

  private

  def with_env(vars)
    old = vars.keys.to_h { |k| [k, ENV[k]] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    old.each { |k, v| ENV[k] = v }
  end
end
