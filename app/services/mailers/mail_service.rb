module Mailers
  class MailService
    class DeliveryError < StandardError; end

    def initialize(primary_provider:, fallback_providers: [])
      @providers = [ primary_provider, *fallback_providers ].compact
    end

    def deliver(message)
      raise DeliveryError, "No mail provider configured" if @providers.empty?

      errors = []

      @providers.each do |provider|
        begin
          result = provider.deliver(message)
          provider_message_id = result.is_a?(Hash) ? result[:provider_message_id] || result["provider_message_id"] : nil
          Rails.logger.info(
            "[Mail] Delivered via #{provider.name} to=#{message.to.join(',')} provider_message_id=#{provider_message_id}"
          )
          return result
        rescue StandardError => e
          errors << "#{provider.name}: #{e.message}"
          Rails.logger.error("[Mail] Provider #{provider.name} failed: #{e.message}")
        end
      end

      raise DeliveryError, "All providers failed. #{errors.join(' | ')}"
    end
  end
end
