source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.0"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 2.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

gem "pagy", "~> 9.1"
gem "ransack", github: "activerecord-hackery/ransack", branch: "main"
gem "premailer-rails"
gem "mailgun-ruby", "~>1.2"

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false

  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "factory_bot_rails"

  gem "rubocop", require: false
  gem "rubocop-capybara", require: false
  gem "rubocop-factory_bot", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "standard", require: false
  gem "standard-performance", require: false
  gem "standard-rails", require: false
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "minitest-spec-rails"
  gem "selenium-webdriver"
  gem "shoulda-context"
  gem "shoulda-matchers"
end

group :development do
  gem "annotate", github: "mlitwiniuk/annotate_models"
  gem "better_errors"
  gem "binding_of_caller"
  gem "ruby-lsp-rails", require: false
  gem "web-console"
end

# Addons
gem "devise"
gem "enum_help"
gem "inline_svg"
gem "responders"
gem "show_for"
gem "simple_form"
gem "simple-navigation"

gem "appsignal", "~> 4.5"
