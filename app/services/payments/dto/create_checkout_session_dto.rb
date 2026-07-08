module Payments
  module Dto
    class CreateCheckoutSessionDto
      attr_reader :customer_id, :amount_cents, :currency, :success_url, :cancel_url, :metadata, :description

      def initialize(customer_id:, amount_cents:, currency:, success_url:, cancel_url:, metadata: {}, description: nil)
        @customer_id = customer_id
        @amount_cents = amount_cents.to_i
        @currency = currency.to_s.downcase
        @success_url = success_url
        @cancel_url = cancel_url
        @metadata = metadata || {}
        @description = description
        validate!
      end

      private

      def validate!
        raise ArgumentError, "amount_cents must be > 0" if amount_cents <= 0
        raise ArgumentError, "currency is required" if currency.blank?
        raise ArgumentError, "success_url is required" if success_url.blank?
        raise ArgumentError, "cancel_url is required" if cancel_url.blank?
      end
    end
  end
end
