require "test_helper"

class SitemapRedirectTest < ActionDispatch::IntegrationTest
  test "redirects /sitemap.xml.gz to the static asset location" do
    get "/sitemap.xml.gz"
    assert_response :moved_permanently
    assert_redirected_to "/sitemaps/sitemap.xml.gz"
  end

  test "redirects numbered sub-sitemaps too" do
    get "/sitemap1.xml.gz"
    assert_response :moved_permanently
    assert_redirected_to "/sitemaps/sitemap1.xml.gz"
  end

  test "constraint blocks unrelated filenames" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/etc-passwd.xml.gz")
    end
  end
end
