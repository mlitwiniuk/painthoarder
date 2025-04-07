# frozen_string_literal: true

# Pagy initializer file
# Custom DaisyUI styling for pagination controls

# Define a custom nav helper with DaisyUI styling
Pagy::Frontend.define_method(:pagy_nav_daisyui) do |pagy, **vars|
  vars[:page_param] ||= pagy.vars[:page_param]

  tags = []
  series = pagy.series(**vars)

  # Previous link
  if pagy.prev
    tags << link_to("«", pagy_url_for(pagy, pagy.prev),
             class: "join-item btn btn-sm",
             'aria-label': "Previous page")
  else
    tags << content_tag(:span, "«", class: "join-item btn btn-sm btn-disabled")
  end

  # Page links
  series.each do |item|
    if item.is_a?(Integer)      # page link
      tags << link_to(item.to_s, pagy_url_for(pagy, item),
               class: "join-item btn btn-sm",
               'aria-label': "Page #{item}")
    elsif item.is_a?(String)    # current page
      tags << content_tag(:a, item,
                       class: "join-item btn btn-sm btn-primary",
                       'aria-current': "page",
                       'aria-label': "Page #{item}")
    elsif item == :gap          # page gap
      tags << content_tag(:span, "...", class: "join-item btn btn-disabled btn-sm btn-ghost")
    end
  end

  # Next link
  if pagy.next
    tags << link_to("»", pagy_url_for(pagy, pagy.next),
             class: "join-item btn btn-sm",
             'aria-label': "Next page")
  else
    tags << content_tag(:span, "»", class: "join-item btn btn-sm btn-disabled")
  end

  content_tag(:div, tags.join.html_safe, class: "join")
end

# Override the default pagy_nav with our custom DaisyUI version
Pagy::Frontend.define_method(:pagy_nav) do |pagy, **vars|
  pagy_nav_daisyui(pagy, **vars)
end
