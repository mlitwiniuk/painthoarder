require "sitemap_generator"

SitemapGenerator::Sitemap.default_host = "https://#{ENV.fetch("HOST", "painthoarder.com")}"
# public/sitemaps is a symlink to ../storage/sitemaps (mounted Kamal volume).
# Thruster serves the gzipped XML directly as a static asset.
SitemapGenerator::Sitemap.public_path   = Rails.public_path.to_s
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"
SitemapGenerator::Sitemap.compress      = true
SitemapGenerator::Sitemap.create_index  = :auto
SitemapGenerator::Sitemap.verbose       = false

SitemapGenerator::Sitemap.create do
  # Note: the gem auto-adds "/" with default priority 1.0 / changefreq "always".
  add brands_path, priority: 0.8, changefreq: "weekly"
  add public_videos_path, priority: 0.7, changefreq: "daily"
  add public_projects_path, priority: 0.7, changefreq: "daily"

  Page.where(status: :issued).find_each do |page|
    add page_path(page), lastmod: page.updated_at, priority: 0.6, changefreq: "monthly"
  end

  Brand.includes(:product_lines).find_each do |brand|
    add brand_path(brand), lastmod: brand.updated_at, priority: 0.8, changefreq: "weekly"

    brand.product_lines.find_each do |line|
      add brand_product_line_path(brand, line),
        lastmod: line.updated_at, priority: 0.7, changefreq: "weekly"
    end
  end

  Paint.includes(product_line: :brand).find_each do |paint|
    line  = paint.product_line
    brand = line.brand
    add brand_product_line_paint_path(brand, line, paint),
      lastmod: paint.updated_at, priority: 0.6, changefreq: "monthly"
  end

  Project.visibility_public.find_each do |project|
    add project_path(project), lastmod: project.updated_at, priority: 0.6, changefreq: "weekly"
  end

  brand_slugs = Brand.pluck(:slug)
  videos_with_matched_paints = VideoPaint.matched.distinct.pluck(:video_id).to_set

  Video.completed.find_each do |video|
    add video_path(video), lastmod: video.updated_at, priority: 0.6, changefreq: "weekly"

    next unless videos_with_matched_paints.include?(video.id)

    brand_slugs.each do |slug|
      add alternatives_video_path(video, brand_slug: slug),
        lastmod: video.updated_at, priority: 0.5, changefreq: "weekly"
    end
  end
end
