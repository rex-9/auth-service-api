module Payments
  module Providers
    class StripeProvider
      def create_customer(email:, name:, metadata:)
        Stripe::Customer.create(
          { email: email, name: name.presence, metadata: metadata },
          { idempotency_key: "stripe-customer-user-#{metadata[:user_id] || metadata['user_id']}" }
        )
      end

      def create_order_checkout_session(customer_id:, order:, metadata:, success_url:, cancel_url:, idempotency_key:)
        Stripe::Checkout::Session.create({
          customer: customer_id, mode: "payment", success_url: success_url, cancel_url: cancel_url,
          line_items: order.order_items.map { |item| {
            quantity: item.quantity,
            price_data: { currency: order.currency, unit_amount: item.unit_price_cents, product_data: { name: item.name } }
          } },
          metadata: metadata, payment_intent_data: { metadata: metadata }
        }, { idempotency_key: idempotency_key })
      end

      def create_checkout_session(dto)
        Stripe::Checkout::Session.create(
          customer: dto.customer_id,
          mode: "payment",
          success_url: dto.success_url,
          cancel_url: dto.cancel_url,
          payment_method_types: [ "card" ],
          line_items: [
            {
              quantity: 1,
              price_data: {
                currency: dto.currency,
                unit_amount: dto.amount_cents,
                product_data: {
                  name: dto.description.presence || "Checkout payment"
                }
              }
            }
          ],
          metadata: dto.metadata
        )
      end

      def create_payment_intent(dto)
        Stripe::PaymentIntent.create(
          customer: dto.customer_id,
          amount: dto.amount_cents,
          currency: dto.currency,
          payment_method_types: dto.payment_method_types,
          description: dto.description,
          metadata: dto.metadata
        )
      end

      def retrieve_price(price_id)
        Stripe::Price.retrieve(price_id)
      end

      def retrieve_product(product_id)
        Stripe::Product.retrieve(product_id)
      end

      def retrieve_payment_intent(payment_intent_id)
        Stripe::PaymentIntent.retrieve(payment_intent_id)
      end

      def retrieve_checkout_session(checkout_session_id)
        Stripe::Checkout::Session.retrieve(checkout_session_id)
      end

      def list_payment_intents(customer_id:, limit: 20)
        Stripe::PaymentIntent.list(customer: customer_id, limit: limit)
      end

      def construct_event(payload:, signature:, webhook_secret:)
        Stripe::Webhook.construct_event(payload, signature, webhook_secret)
      end
    end
  end
end
