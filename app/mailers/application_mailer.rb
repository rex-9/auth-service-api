class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM_ADDRESS", "no-reply@example.com") }
  layout "mailer"
end
