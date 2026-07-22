module Payments
  class CreateStripeCheckoutSession
    class Error < StandardError; end

    def initialize(provider: Providers::StripeProvider.new, customer_service: FindOrCreateStripeCustomer.new)
      @provider = provider
      @customer_service = customer_service
    end

    def call(user:, order:)
      raise Error, "Order not found" unless order.user_id == user.id
      raise Error, "Order is not payable" unless order.payable?

      payment = order.payments.create!(user: user, amount_cents: order.total_cents, currency: order.currency, status: "pending")
      customer_id = @customer_service.call(user: user)
      metadata = {
        order_id: order.id, order_number: order.order_number,
        payment_id: payment.id, payment_number: payment.payment_number
      }
      session = @provider.create_order_checkout_session(
        customer_id: customer_id, order: order, metadata: metadata,
        success_url: configured_url("FRONTEND_PAYMENT_SUCCESS_URL"),
        cancel_url: configured_url("FRONTEND_PAYMENT_CANCEL_URL"),
        idempotency_key: "stripe-checkout-payment-#{payment.id}"
      )
      payment.update!(stripe_customer_id: customer_id, stripe_checkout_session_id: session.id)
      { order: order, payment: payment, checkout_url: session.url }
    rescue Stripe::StripeError => e
      payment&.transition_to!("failed", failed_at: Time.current, failure_code: e.code, failure_message: e.message.to_s.first(500))
      raise Error, "Stripe could not create the Checkout Session"
    rescue Error => e
      payment&.transition_to!("failed", failed_at: Time.current, failure_code: "configuration", failure_message: e.message.to_s.first(500))
      raise
    end

    private

    def configured_url(key)
      ENV[key].presence || Rails.application.credentials.dig(:stripe, key.downcase.to_sym) || raise(Error, "Missing #{key}")
    end
  end
end
