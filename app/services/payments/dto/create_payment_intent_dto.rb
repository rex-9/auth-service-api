module Payments
  module Dto
    class CreatePaymentIntentDto
      attr_reader :customer_id, :amount_cents, :currency, :metadata, :description, :payment_method_types

      def initialize(customer_id:, amount_cents:, currency:, metadata: {}, description: nil, payment_method_types: ["card"])
        @customer_id = customer_id
        @amount_cents = amount_cents.to_i
        @currency = currency.to_s.downcase
        @metadata = metadata || {}
        @description = description
        @payment_method_types = Array(payment_method_types).presence || ["card"]
        validate!
      end

      private

      def validate!
        raise ArgumentError, "amount_cents must be > 0" if amount_cents <= 0
        raise ArgumentError, "currency is required" if currency.blank?
      end
    end
  end
end
