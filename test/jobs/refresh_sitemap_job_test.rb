require "test_helper"

class RefreshSitemapJobTest < ActiveSupport::TestCase
  test "invokes the sitemap_generator interpreter with the config file" do
    SitemapGenerator::Interpreter.expects(:run).with(
      config_file: Rails.root.join("config", "sitemap.rb")
    )
    RefreshSitemapJob.new.perform
  end

  test "ensures the storage/sitemaps directory exists" do
    SitemapGenerator::Interpreter.stubs(:run)
    dir = Rails.root.join("storage", "sitemaps")
    FileUtils.rm_rf(dir)
    RefreshSitemapJob.new.perform
    assert Dir.exist?(dir)
  end
end
