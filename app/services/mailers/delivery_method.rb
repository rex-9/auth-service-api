module Mailers
  class DeliveryMethod
    def initialize(options = {})
      @mail_service = options[:mail_service] || ProviderRegistry.build_service
    end

    def deliver!(mail)
      message = MailMessage.from_mail(mail)
      @mail_service.deliver(message)
    rescue StandardError => e
      Rails.logger.error("[Mail] Delivery adapter failed: #{e.message}")
      raise e
    end
  end
end
