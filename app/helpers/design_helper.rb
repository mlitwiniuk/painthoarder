# frozen_string_literal: true

# Building blocks of the "C · Bold" design system: icons, status tags,
# match-quality meters and main-navigation state. Styles live in
# app/assets/stylesheets/components/painthoarder.css.
module DesignHelper
  ICON_PATHS = {
    search: '<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>',
    check: '<path d="M5 12l5 5 9-10"/>',
    heart: '<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>',
    ban: '<circle cx="12" cy="12" r="8"/><path d="M6.5 17.5l11-11"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    x: '<path d="M6 6l12 12M18 6L6 18"/>',
    alert: '<circle cx="12" cy="12" r="9"/><path d="M12 7v6M12 16.5v.5"/>',
    back: '<path d="M15 5l-7 7 7 7"/>',
    wheel: '<circle cx="12" cy="12" r="9"/><path d="M12 3v18M3 12h18"/>',
    rack: '<rect x="3" y="4" width="18" height="6" rx="1"/><rect x="3" y="14" width="18" height="6" rx="1"/>',
    projects: '<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="9" cy="9" r="2"/><path d="M21 16l-5-5-9 9"/>',
    videos: '<rect x="2" y="5" width="20" height="14" rx="2"/><path d="M10 9l5 3-5 3z"/>',
    account: '<circle cx="12" cy="8" r="4"/><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6"/>',
    upload: '<path d="M12 16V4M6 10l6-6 6 6M4 20h16"/>'
  }.freeze

  STATUS_TAGS = {
    "owned" => {label: "Owned", icon: :check, css: "tag-owned"},
    "wishlist" => {label: "Wanted", icon: :heart, css: "tag-wanted"},
    "avoid" => {label: "Avoid", icon: :ban, css: "tag-avoid"}
  }.freeze

  # Match quality bands for CIEDE2000 ΔE (see design foundations, 03 · Status).
  MATCH_QUALITY = [
    {max: 1.0, level: 4, label: "Near-identical", meaning: "Swap freely"},
    {max: 3.0, level: 3, label: "Very close", meaning: "Hard to tell on the model"},
    {max: 6.0, level: 2, label: "Close", meaning: "Same family, visible side by side"},
    {max: Float::INFINITY, level: 1, label: "Noticeable", meaning: "Different paint, similar idea"}
  ].freeze

  def ph_icon(name, size: 18, stroke: 2.2, css: nil)
    content_tag(:svg, ICON_PATHS.fetch(name.to_sym).html_safe,
      width: size, height: size, viewBox: "0 0 24 24", fill: "none",
      stroke: "currentColor", "stroke-width": stroke,
      "stroke-linecap": "round", "stroke-linejoin": "round",
      class: css, "aria-hidden": "true")
  end

  # The PaintHoarder drop mark.
  def brand_mark(size: 24)
    content_tag(:svg, width: size, height: (size * 30 / 26.0).round, viewBox: "0 0 26 30", "aria-hidden": "true") do
      tag.path(d: "M13 1C13 1 3 13 3 19a10 10 0 0 0 20 0C23 13 13 1 13 1z", fill: "#FF6B2C") +
        tag.path(d: "M9 20a4 4 0 0 0 4 4", stroke: "#141216", "stroke-width": "2.4", fill: "none", "stroke-linecap": "round")
    end
  end

  # Status tag: a word, an icon and a colour. `nil` status renders nothing
  # unless `add: true`, which renders the dashed "Add" tag.
  def status_tag(status, size: nil, count: nil, add: false, css: nil)
    config = STATUS_TAGS[status.to_s]
    if config.nil?
      return "".html_safe unless add

      config = {label: "Add", icon: :plus, css: "tag-add"}
    end

    label = config[:label]
    label = "#{label} × #{count}" if count && count > 1
    icon_size = {sm: 11, lg: 14}.fetch(size, 12)
    classes = ["tag", config[:css], ("tag-#{size}" if size), css].compact.join(" ")
    content_tag(:span, safe_join([ph_icon(config[:icon], size: icon_size, stroke: 3), label]), class: classes)
  end

  def status_label(status)
    STATUS_TAGS.dig(status.to_s, :label) || "Not mine"
  end

  def match_quality(delta_e)
    return if delta_e.nil?

    MATCH_QUALITY.find { |band| delta_e.to_f < band[:max] }
  end

  def match_meter(level, small: false)
    segments = Array.new(4) { |i| tag.span(class: ("on" if i < level.to_i)) }
    content_tag(:span, safe_join(segments), class: ["match-meter", ("match-meter-sm" if small)].compact.join(" "), "aria-hidden": "true")
  end

  # Which top-level section the current page belongs to.
  def main_nav_section
    case controller_name
    when "user_paints" then :rack
    when "paints", "brands", "product_lines", "directory_paints" then :catalogue
    when "projects", "project_updates" then :projects
    when "videos", "video_paints" then :videos
    when "dashboard" then :dashboard
    when "registrations" then :account
    end
  end

  def nav_current(section)
    (main_nav_section == section) ? "page" : nil
  end

  def user_initial(user)
    user.username.to_s.first.to_s.upcase.presence || "?"
  end
end
