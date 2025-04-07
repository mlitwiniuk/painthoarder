class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "noreply@painthoarder.local"), reply_to: ENV.fetch("MAILER_REPLY_TO", ENV.fetch("MAILER_FROM", "noreply@painthoarder.local"))
  layout "mailer"
end
