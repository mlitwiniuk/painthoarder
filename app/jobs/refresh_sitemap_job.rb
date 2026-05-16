class RefreshSitemapJob < ApplicationJob
  queue_as :default

  def perform
    # The target directory of the public/sitemaps symlink.
    FileUtils.mkdir_p(Rails.root.join("storage", "sitemaps"))
    SitemapGenerator::Interpreter.run(config_file: Rails.root.join("config", "sitemap.rb"))
  end
end
