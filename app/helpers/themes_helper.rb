# frozen_string_literal: true

module ThemesHelper
  # First entry is the default (dark). Keep in sync with theme_controller.js.
  def themes
    %w[painthoarder painthoarder-light]
  end

  def theme_label(theme)
    theme == "painthoarder-light" ? "Light" : "Dark"
  end
end
