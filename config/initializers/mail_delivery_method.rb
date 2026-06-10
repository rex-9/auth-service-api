require Rails.root.join("app/services/mail_providers/resend_mail_provider")
require Rails.root.join("app/services/mail_providers/postmark_mail_provider")
require Rails.root.join("app/services/mailers/mail_message")
require Rails.root.join("app/services/mailers/mail_service")
require Rails.root.join("app/services/mailers/provider_registry")
require Rails.root.join("app/services/mailers/delivery_method")

ActionMailer::Base.add_delivery_method :provider_mail, Mailers::DeliveryMethod
