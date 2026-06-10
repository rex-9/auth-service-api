module Mailers
  class ProviderRegistry
    PROVIDERS = {
      "resend" => MailProviders::ResendMailProvider,
      "postmark" => MailProviders::PostmarkMailProvider
    }.freeze

    def self.build_service
      primary_name = ENV.fetch("MAIL_MAILER", "resend").downcase
      fallback_names = ENV.fetch("MAIL_FALLBACK_MAILERS", "").split(",").map(&:strip).reject(&:empty?)

      primary_provider = build_provider(primary_name)
      fallback_providers = fallback_names.filter_map { |name| build_provider(name) }

      MailService.new(primary_provider: primary_provider, fallback_providers: fallback_providers)
    end

    def self.build_provider(name)
      provider_class = PROVIDERS[name.to_s.downcase]
      unless provider_class
        raise MailService::DeliveryError, "Unknown mail provider: #{name}. Supported: #{PROVIDERS.keys.join(', ')}"
      end

      provider_class.new
    end
  end
end
