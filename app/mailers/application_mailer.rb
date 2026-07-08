class ApplicationMailer < ActionMailer::Base
  default from: -> {
    address = ENV.fetch("MAIL_FROM_ADDRESS", "no-reply@example.com")
    name = ENV.fetch("MAIL_FROM_NAME", "").strip
    name.present? ? "#{name} <#{address}>" : address
  }
  layout "mailer"
end
