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

  # Build the full directory URL for a paint: /brands/:brand/lines/:product_line/paints/:paint
  def directory_paint_path_for(paint)
    brand_product_line_paint_path(paint.product_line.brand, paint.product_line, paint.slug)
  end

  # Human-readable badge for a paint similarity score.
  # color strategy -> CIEDE2000 ΔE; hue strategy -> degrees off the hue family.
  def similarity_score_label(strategy, score)
    return if score.nil?

    if strategy == "color"
      "ΔE #{score.round(1)}"
    else
      "#{score.round}° off"
    end
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
      url_for(optimized_variant(project.cover_photo, :og))
    elsif project.project_updates.joins(:photos_attachments).any?
      recent_photo = project.project_updates.joins(:photos_attachments).first&.photos&.first
      recent_photo ? url_for(optimized_variant(recent_photo, :og)) : asset_url("og-default.png")
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

  # Brand directory OG tag helpers
  def brand_index_og_tags
    {
      site_name: "PaintHoarder",
      type: "website",
      url: request.original_url,
      title: "Paint Brands Directory | PaintHoarder",
      description: "Browse all miniature paint brands. Find paints from Citadel, Vallejo, Army Painter, Scale75 and more.",
      image: asset_url("og-default.png"),
      image_alt: "PaintHoarder Paint Brands Directory"
    }
  end

  def brand_show_og_tags(brand)
    {
      site_name: "PaintHoarder",
      type: "website",
      url: request.original_url,
      title: "#{brand.name} Paints | PaintHoarder",
      description: "Browse all #{brand.name} paint product lines and colors for your miniature painting projects.",
      image: brand.logo.attached? ? url_for(brand.logo) : asset_url("og-default.png"),
      image_alt: "#{brand.name} - Miniature Paints"
    }
  end

  def product_line_og_tags(brand, product_line)
    {
      site_name: "PaintHoarder",
      type: "website",
      url: request.original_url,
      title: "#{product_line.name} by #{brand.name} | PaintHoarder",
      description: product_line.description.presence || "Browse all #{product_line.name} paints by #{brand.name}.",
      image: asset_url("og-default.png"),
      image_alt: "#{product_line.name} by #{brand.name}"
    }
  end

  def directory_paint_og_tags(brand, product_line, paint)
    {
      site_name: "PaintHoarder",
      type: "website",
      url: request.original_url,
      title: "#{paint.name} - #{product_line.name} by #{brand.name} | PaintHoarder",
      description: "#{paint.name} (#{paint.code}) from #{product_line.name} by #{brand.name}. Color: #{paint.hex_color}.",
      image: asset_url("og-default.png"),
      image_alt: "#{paint.name} - #{brand.name}"
    }
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
      url_for(optimized_variant(project.cover_photo, :og))
    elsif project.project_updates.joins(:photos_attachments).any?
      recent_photo = project.project_updates.joins(:photos_attachments).first&.photos&.first
      recent_photo ? url_for(optimized_variant(recent_photo, :og)) : asset_url("og-project.png")
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

  def brand_index_structured_data(brands)
    list_items = brands.map.with_index do |brand, index|
      {
        "@type" => "ListItem",
        "position" => index + 1,
        "item" => {
          "@type" => "Brand",
          "@id" => brand_url(brand),
          "name" => brand.name,
          "url" => brand_url(brand)
        }
      }
    end

    {
      "@context" => "https://schema.org",
      "@type" => "ItemList",
      "name" => "Miniature Paint Brands",
      "description" => "Directory of miniature paint brands",
      "url" => request.original_url,
      "numberOfItems" => brands.length,
      "itemListElement" => list_items
    }
  end

  def brand_structured_data(brand, product_lines)
    {
      "@context" => "https://schema.org",
      "@type" => "Brand",
      "name" => brand.name,
      "url" => brand_url(brand),
      "description" => "#{brand.name} miniature paints",
      "mainEntityOfPage" => {
        "@type" => "WebPage",
        "@id" => brand_url(brand)
      }
    }
  end

  def product_line_structured_data(brand, product_line, paints)
    {
      "@context" => "https://schema.org",
      "@type" => "ProductGroup",
      "name" => "#{product_line.name} by #{brand.name}",
      "description" => product_line.description.presence || "#{product_line.name} paint range by #{brand.name}",
      "brand" => {
        "@type" => "Brand",
        "name" => brand.name,
        "url" => brand_url(brand)
      },
      "url" => brand_product_line_url(brand, product_line),
      "numberOfItems" => paints.count
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

  # Calculate reading time for content based on average reading speed
  def reading_time(content)
    return 0 if content.blank?

    # Strip HTML tags and count words
    word_count = strip_tags(content.to_s).split.length

    # Average reading speed is 200 words per minute
    reading_time = (word_count / 200.0).ceil

    # Minimum 1 minute
    [reading_time, 1].max
  end

  # Status helper methods
  def status_icons
    {
      'heart' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />',
      'check' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />',
      'ban' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 715.636 5.636m12.728 12.728L5.636 5.636" />',
      'trash' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />',
      'edit' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />',
      'plus' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />',
      'star' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />',
      'x' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />'
    }
  end

  def status_icon(icon_name, size_class = "h-4 w-4")
    return "" unless status_icons[icon_name]

    content_tag :svg, status_icons[icon_name].html_safe,
      xmlns: "http://www.w3.org/2000/svg",
      class: size_class,
      fill: "none",
      viewBox: "0 0 24 24",
      stroke: "currentColor"
  end

  def status_transitions(current_status)
    transitions = {
      'owned' => [
        {
          status: 'wishlist',
          label: 'Move to Wishlist',
          short_label: 'Wishlist',
          icon: 'heart',
          class: 'btn-warning',
          tooltip: 'Move to wishlist'
        },
        {
          status: 'avoid',
          label: 'Mark as Avoid',
          short_label: 'Avoid',
          icon: 'ban',
          class: 'btn-error',
          tooltip: 'Mark as avoid'
        }
      ],
      'wishlist' => [
        {
          status: 'owned',
          label: 'Mark as Owned',
          short_label: 'Own',
          icon: 'check',
          class: 'btn-success',
          tooltip: 'Mark as owned'
        },
        {
          status: 'avoid',
          label: 'Mark as Avoid',
          short_label: 'Avoid',
          icon: 'ban',
          class: 'btn-error',
          tooltip: 'Mark as avoid'
        }
      ],
      'avoid' => [
        {
          status: 'owned',
          label: 'Mark as Owned',
          short_label: 'Own',
          icon: 'check',
          class: 'btn-success',
          tooltip: 'Mark as owned'
        },
        {
          status: 'wishlist',
          label: 'Add to Wishlist',
          short_label: 'Wishlist',
          icon: 'heart',
          class: 'btn-warning',
          tooltip: 'Add to wishlist'
        }
      ],
      'not_in_collection' => [
        {
          status: 'owned',
          label: 'Add as Owned',
          short_label: 'Own',
          icon: 'check',
          class: 'btn-success',
          tooltip: 'Add as owned'
        },
        {
          status: 'wishlist',
          label: 'Add to Wishlist',
          short_label: 'Wishlist',
          icon: 'heart',
          class: 'btn-warning',
          tooltip: 'Add to wishlist'
        },
        {
          status: 'avoid',
          label: 'Mark as Avoid',
          short_label: 'Avoid',
          icon: 'ban',
          class: 'btn-error',
          tooltip: 'Mark as avoid'
        }
      ]
    }

    transitions[current_status] || []
  end

  def status_badge_config(status)
    badges = {
      'owned' => {
        class: 'badge-success',
        icon: 'check',
        label: 'Owned',
        color: 'text-success'
      },
      'wishlist' => {
        class: 'badge-warning',
        icon: 'heart',
        label: 'Wishlist',
        color: 'text-warning'
      },
      'avoid' => {
        class: 'badge-error',
        icon: 'ban',
        label: 'Avoiding',
        color: 'text-error'
      },
      'not_in_collection' => {
        class: 'badge-ghost',
        icon: 'plus',
        label: 'Not in Collection',
        color: 'text-base-content'
      }
    }

    badges[status] || {}
  end

  def status_display(status)
    config = status_badge_config(status)
    {
      class: config[:class],
      icon: config[:icon],
      label: config[:label],
      color: config[:color]
    }
  end
end
