module ApplicationHelper
  # Convert RGB values to HSL (Hue, Saturation, Lightness)
  # @param r [Integer] Red value (0-255)
  # @param g [Integer] Green value (0-255)
  # @param b [Integer] Blue value (0-255)
  # @return [Array] Array containing [h, s, l] values where h is in degrees (0-360) and s, l are percentages (0-100)
  def rgb_to_hsl(r, g, b)
    r /= 255.0
    g /= 255.0
    b /= 255.0

    max = [r, g, b].max
    min = [r, g, b].min

    h = s = l = (max + min) / 2.0

    if max == min
      h = s = 0 # achromatic
    else
      d = max - min
      s = (l > 0.5) ? d / (2.0 - max - min) : d / (max + min)

      case max
      when r
        h = (g - b) / d + ((g < b) ? 6 : 0)
      when g
        h = (b - r) / d + 2
      when b
        h = (r - g) / d + 4
      end

      h /= 6.0
    end

    # Convert to degrees and percentages
    h = (h * 360).round
    s = (s * 100).round
    l = (l * 100).round

    [h, s, l]
  end

  include Pagy::Frontend

  def container_class
    if controller_name == "pages" && action_name == "welcome"
      "container-full"
    else
      "container"
    end
  end

  def gravatar_for(user, options = {size: 200})
    hash = Digest::MD5.hexdigest(user.email.downcase)
    size = options[:size]
    gravatar_url = "https://robohash.org/#{hash}?gravatar=hashed&size=#{size}x#{size}&bgset=bg1"
    image_tag(gravatar_url, alt: user.username, class: "img-circle")
  end

  def user_paint_status_icon(status)
    case status
    when "owned"
      "✅"
    when "wishlist"
      "❤️"
    when "avoid"
      "❌"
    end
  end

  # Open Graph meta tag helpers
  def default_og_tags
    {
      site_name: "PaintHoarder",
      type: "website",
      url: request.original_url,
      title: content_for(:title) || "PaintHoarder - Share & Track Your Miniature Painting Projects",
      description: "Share your miniature painting projects and manage your paint collection. Connect with fellow painters in the ultimate hobby platform for miniature enthusiasts.",
      image: asset_url("og-default.png"),
      image_alt: "PaintHoarder - Share Your Miniature Painting Projects & Manage Paint Collection",
      image_width: "1200",
      image_height: "630",
      locale: "en_US"
    }
  end

  def project_og_tags(project)
    description = if project.description.present?
      strip_tags(project.description).truncate(160)
    else
      "#{project.user.username || project.user.email.split("@").first}'s miniature painting project: #{project.title}"
    end

    image_url = if project.cover_photo.attached?
      project.cover_photo.variant(resize_to_fill: [1200, 630]).processed.url
    elsif project.project_updates.joins(:photos_attachments).any?
      recent_photo = project.project_updates.joins(:photos_attachments).first&.photos&.first
      recent_photo ? recent_photo.variant(resize_to_fill: [1200, 630]).processed.url : asset_url("og-default.png")
    else
      asset_url("og-project.png")
    end

    {
      site_name: "PaintHoarder",
      type: "article",
      url: restricted_project_url(project.secret_token),
      title: "#{project.title} - PaintHoarder",
      description: description,
      image: image_url,
      image_alt: "#{project.title} - Miniature painting project",
      article_author: project.user.username || project.user.email.split("@").first,
      article_published_time: project.created_at.iso8601,
      article_modified_time: project.updated_at.iso8601
    }
  end

  def projects_index_og_tags(is_public = false)
    title = is_public ? "Community Projects - PaintHoarder" : "My Projects - PaintHoarder"
    description = if is_public
      "Discover amazing miniature painting projects from the PaintHoarder community. Get inspired by fellow painters' work and techniques."
    else
      "Manage and showcase your miniature painting projects. Document your progress and share your hobby journey."
    end

    {
      site_name: "PaintHoarder",
      type: "website",
      url: request.original_url,
      title: title,
      description: description,
      image: asset_url("og-gallery.png"),
      image_alt: is_public ? "Community miniature painting projects" : "Personal miniature painting projects"
    }
  end

  def render_og_tags(tags = {})
    og_data = default_og_tags.merge(tags)

    content_for :head do
      safe_join([
        tag.meta(property: "og:site_name", content: og_data[:site_name]),
        tag.meta(property: "og:type", content: og_data[:type]),
        tag.meta(property: "og:url", content: og_data[:url]),
        tag.meta(property: "og:title", content: og_data[:title]),
        tag.meta(property: "og:description", content: og_data[:description]),
        tag.meta(property: "og:image", content: og_data[:image]),
        tag.meta(property: "og:image:alt", content: og_data[:image_alt]),
        tag.meta(property: "og:image:width", content: og_data[:image_width]),
        tag.meta(property: "og:image:height", content: og_data[:image_height]),
        tag.meta(property: "og:locale", content: og_data[:locale]),
        tag.meta(name: "twitter:card", content: "summary_large_image"),
        tag.meta(name: "twitter:site", content: "@painthoarder"),
        tag.meta(name: "twitter:creator", content: "@painthoarder"),
        tag.meta(name: "twitter:title", content: og_data[:title]),
        tag.meta(name: "twitter:description", content: og_data[:description]),
        tag.meta(name: "twitter:image", content: og_data[:image]),
        tag.meta(name: "twitter:image:alt", content: og_data[:image_alt]),
        tag.meta(name: "twitter:label1", content: "Category"),
        tag.meta(name: "twitter:data1", content: "Miniature Painting"),
        (tag.meta(property: "article:author", content: og_data[:article_author]) if og_data[:article_author]),
        (tag.meta(property: "article:section", content: "Miniature Painting") if og_data[:article_author]),
        (tag.meta(property: "article:tag", content: "miniature painting, hobby, community") if og_data[:article_author]),
        (tag.meta(property: "article:published_time", content: og_data[:article_published_time]) if og_data[:article_published_time]),
        (tag.meta(property: "article:modified_time", content: og_data[:article_modified_time]) if og_data[:article_modified_time])
      ].compact, "\n")
    end
  end

  # Structured Data (JSON-LD) helpers for SEO
  def default_structured_data
    {
      "@context" => "https://schema.org",
      "@type" => ["WebSite", "SocialMediaPosting"],
      "name" => "PaintHoarder",
      "url" => root_url,
      "description" => "Share your miniature painting projects and manage your paint collection. Connect with fellow painters in the ultimate hobby platform for miniature enthusiasts.",
      "keywords" => "miniature painting, hobby community, paint collection, project sharing, Warhammer, tabletop gaming",
      "audience" => {
        "@type" => "Audience",
        "audienceType" => "hobbyists, miniature painters, tabletop gamers"
      },
      "potentialAction" => [
        {
          "@type" => "SearchAction",
          "target" => "#{paints_url}?search={search_term_string}",
          "query-input" => "required name=search_term_string"
        },
        {
          "@type" => "ViewAction",
          "name" => "Browse Community Projects",
          "target" => "#{public_projects_url}"
        }
      ],
      "sameAs" => [
        "https://github.com/mlitwiniuk/painthoarder"
      ]
    }
  end

  def project_structured_data(project)
    author_name = project.user.username.present? ? project.user.username : project.user.email.split("@").first

    image_url = if project.cover_photo.attached?
      project.cover_photo.variant(resize_to_limit: [1200, 630]).processed.url
    elsif project.project_updates.joins(:photos_attachments).any?
      recent_photo = project.project_updates.joins(:photos_attachments).first&.photos&.first
      recent_photo ? recent_photo.variant(resize_to_limit: [1200, 630]).processed.url : asset_url("og-project.png")
    else
      asset_url("og-project.png")
    end

    {
      "@context" => "https://schema.org",
      "@type" => "CreativeWork",
      "headline" => project.title,
      "description" => project.description.present? ? strip_tags(project.description).truncate(160) : "Miniature painting project by #{author_name}",
      "image" => image_url,
      "author" => {
        "@type" => "Person",
        "name" => author_name
      },
      "datePublished" => project.created_at.iso8601,
      "dateModified" => project.updated_at.iso8601,
      "url" => restricted_project_url(project.secret_token),
      "mainEntityOfPage" => {
        "@type" => "WebPage",
        "@id" => restricted_project_url(project.secret_token)
      },
      "keywords" => "miniature painting, hobby project, #{project.visibility}, paint collection, community sharing",
      "genre" => "Miniature Painting",
      "artform" => "Miniature Painting",
      "isAccessibleForFree" => project.visibility != "private",
      "creativeWorkStatus" => project.project_updates.any? ? "Published" : "Draft"
    }
  end

  def projects_index_structured_data(projects, is_public = false)
    list_items = projects.limit(10).map.with_index do |project, index|
      author_name = project.user.username.present? ? project.user.username : project.user.email.split("@").first
      project_url = restricted_project_url(project.secret_token)

      {
        "@type" => "ListItem",
        "position" => index + 1,
        "item" => {
          "@type" => "CreativeWork",
          "@id" => project_url,
          "name" => project.title,
          "description" => project.description.present? ? strip_tags(project.description).truncate(100) : "Miniature painting project",
          "author" => {
            "@type" => "Person",
            "name" => author_name
          },
          "datePublished" => project.created_at.iso8601,
          "url" => project_url
        }
      }
    end

    {
      "@context" => "https://schema.org",
      "@type" => "ItemList",
      "name" => is_public ? "Community Miniature Painting Projects" : "Personal Miniature Painting Projects",
      "description" => is_public ? "Browse amazing miniature painting projects from the community" : "Manage your miniature painting project collection",
      "url" => request.original_url,
      "numberOfItems" => projects.count,
      "itemListElement" => list_items
    }
  end

  def render_structured_data(data)
    content_for :head do
      tag.script(data.to_json.html_safe, type: "application/ld+json")
    end
  end

  def organization_structured_data
    {
      "@context" => "https://schema.org",
      "@type" => "Organization",
      "name" => "PaintHoarder",
      "url" => root_url,
      "logo" => {
        "@type" => "ImageObject",
        "url" => asset_url("icon.png"),
        "width" => 512,
        "height" => 512
      },
      "description" => "The ultimate platform for miniature painting enthusiasts to share projects, track paint collections, and connect with the hobby community.",
      "foundingDate" => "2024",
      "applicationCategory" => "Hobby & Craft Application",
      "operatingSystem" => "Web Browser",
      "offers" => {
        "@type" => "Offer",
        "price" => "0",
        "priceCurrency" => "USD"
      },
      "audience" => {
        "@type" => "Audience",
        "audienceType" => "Miniature painters, hobbyists, tabletop gamers"
      },
      "sameAs" => [
        "https://github.com/mlitwiniuk/painthoarder"
      ]
    }
  end

  def website_structured_data
    {
      "@context" => "https://schema.org",
      "@type" => "WebApplication",
      "name" => "PaintHoarder",
      "url" => root_url,
      "applicationCategory" => "Hobby & Craft",
      "operatingSystem" => "Web Browser",
      "description" => "Share your miniature painting projects and manage your paint collection. Connect with fellow painters in the ultimate hobby platform.",
      "featureList" => [
        "Paint collection tracking",
        "Project documentation",
        "Community sharing",
        "Progress tracking",
        "Color matching",
        "Wishlist management"
      ],
      "screenshot" => asset_url("og-default.png"),
      "offers" => {
        "@type" => "Offer",
        "price" => "0",
        "priceCurrency" => "USD"
      }
    }
  end
end
