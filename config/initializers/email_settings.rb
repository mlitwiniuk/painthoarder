# ActionMailer::Base.default_url_options[:locale] = I18n.locale

if Rails.env.development?
  ActionMailer::Base.default_url_options[:host] = ENV["HOST"] ||
    "painthoarder.test"
  ActionMailer::Base.default_url_options[:protocol] = "http"
  ActionMailer::Base.asset_host = "http://#{ActionMailer::Base.default_url_options[:host]}"

  ActionMailer::Base.delivery_method = :smtp

  ActionMailer::Base.smtp_settings = {address: "localhost", port: 1025} # mailcatcher or mailpit
elsif Rails.env.production?
  ActionMailer::Base.delivery_method = :mailgun
  ActionMailer::Base.mailgun_settings = {
    api_key: ENV["MAILGUN_API_KEY"],
    domain: ENV["MAILGUN_DOMAIN"],
    api_host: "api.eu.mailgun.net"
    # timeout: 20 # Default depends on rest-client, whose default is 60s. Added in 1.2.3.
  }
  ActionMailer::Base.perform_deliveries = true
  # ActionMailer::Base.smtp_settings = {
  #   address: ENV["SMTP_ADDRESS"],
  #   port: ENV["SMTP_PORT"],
  #   domain: ENV["HOST"],
  #   user_name: ENV["SMTP_USERNAME"],
  #   password: ENV["SMTP_PASSWORD"],
  #   authentication: :plain,
  #   enable_starttls_auto: true
  # }

  if ENV["HOST"].blank?
    raise StandardError,
      "You need to set up ActionMailer::Base.default_url_options[:host] and other ActionMailer settings for production environment in #{__FILE__}"
  end
  ActionMailer::Base.default_url_options[:host] = ENV["HOST"]
  ActionMailer::Base.default_url_options[:protocol] = "https"
elsif Rails.env.staging?
  ActionMailer::Base.delivery_method = :mailgun
  ActionMailer::Base.mailgun_settings = {
    api_key: ENV["MAILGUN_API_KEY"],
    domain: ENV["MAILGUN_DOMAIN"],
    api_host: "api.eu.mailgun.net"
  }
  ActionMailer::Base.perform_deliveries = true
  if ENV["HOST"].blank?
    raise StandardError,
      "You need to set up ActionMailer::Base.default_url_options[:host] and other ActionMailer settings for production environment in #{__FILE__}"
  end
  ActionMailer::Base.default_url_options[:host] = ENV["HOST"]
  ActionMailer::Base.default_url_options[:protocol] = "https"
elsif Rails.env.test?
  ActionMailer::Base.default_url_options[:host] = ENV.fetch("HOST", "painthoarder.local")
  ActionMailer::Base.default_url_options[:protocol] = "http"
else
  fail StandardError, "Not supported environment: #{Rails.env}, check: #{__FILE__}"
end
