module Payments
  class StripeService
    class Error < StandardError; end

    def initialize(provider: Providers::StripeProvider.new)
      @provider = provider
    end

    def create_checkout_session(dto:, user: nil)
      session = @provider.create_checkout_session(dto)
      upsert_transaction_from_checkout_session(session, user: user)
      session
    rescue Stripe::StripeError => e
      Rails.logger.error("[Stripe] create_checkout_session failed: #{e.message}")
      raise Error, e.message
    end

    def create_payment_intent(dto:, user: nil)
      payment_intent = @provider.create_payment_intent(dto)
      upsert_transaction_from_payment_intent(payment_intent, user: user)
      payment_intent
    rescue Stripe::StripeError => e
      Rails.logger.error("[Stripe] create_payment_intent failed: #{e.message}")
      raise Error, e.message
    end

    def create_payment_intent_from_price_payload(payload:, user: nil)
      price_id = payload[:price_id].presence
      product_id = payload[:product_id].presence
      quantity = payload[:quantity].to_i
      quantity = 1 if quantity <= 0

      raise ArgumentError, "price_id is required" if price_id.blank?

      price = @provider.retrieve_price(price_id)
      validate_price_payload!(price: price, product_id: product_id, currency: payload[:currency])

      dto = Payments::Dto::CreatePaymentIntentDto.new(
        customer_id: payload[:customer_id].presence,
        amount_cents: (price.unit_amount.to_i * quantity),
        currency: price.currency,
        description: payload[:description].presence || "Payment for #{price_id}",
        metadata: (payload[:metadata] || {}).merge(
          "price_id" => price_id,
          "product_id" => product_id,
          "quantity" => quantity
        ),
        payment_method_types: [ payload[:payment_method_type].presence || "card" ]
      )

      create_payment_intent(dto: dto, user: user)
    rescue Stripe::StripeError => e
      Rails.logger.error("[Stripe] create_payment_intent_from_price_payload failed: #{e.message}")
      raise Error, e.message
    end

    def verify_payment_status(payment_intent_id:)
      payment_intent = @provider.retrieve_payment_intent(payment_intent_id)
      upsert_transaction_from_payment_intent(payment_intent)
      { id: payment_intent.id, status: payment_intent.status }
    rescue Stripe::StripeError => e
      Rails.logger.error("[Stripe] verify_payment_status failed: #{e.message}")
      raise Error, e.message
    end

    def retrieve_payment_details(payment_intent_id: nil, checkout_session_id: nil)
      transaction = find_transaction(payment_intent_id: payment_intent_id, checkout_session_id: checkout_session_id)
      return transaction if transaction.present?

      if payment_intent_id.present?
        payment_intent = @provider.retrieve_payment_intent(payment_intent_id)
        return upsert_transaction_from_payment_intent(payment_intent)
      end

      if checkout_session_id.present?
        session = @provider.retrieve_checkout_session(checkout_session_id)
        return upsert_transaction_from_checkout_session(session)
      end

      raise Error, "payment_intent_id or checkout_session_id is required"
    rescue Stripe::StripeError => e
      Rails.logger.error("[Stripe] retrieve_payment_details failed: #{e.message}")
      raise Error, e.message
    end

    def list_customer_payments(customer_id:, limit: 20)
      PaymentTransaction.for_customer(customer_id).recent_first.limit(limit)
    end

    def retrieve_product_details(product_id:, price_id:)
      raise ArgumentError, "product_id is required" if product_id.blank?
      raise ArgumentError, "price_id is required" if price_id.blank?

      product = @provider.retrieve_product(product_id)
      price = @provider.retrieve_price(price_id)

      if price.product.to_s != product.id.to_s
        raise ArgumentError, "price_id does not belong to product_id"
      end

      {
        product: {
          id: product.id,
          title: product.name,
          description: product.description,
          photo: Array(product.images).first,
          photos: Array(product.images),
          active: product.active,
          metadata: stripe_metadata(product.metadata)
        },
        price: {
          id: price.id,
          active: price.active,
          currency: price.currency,
          unit_amount: price.unit_amount,
          unit_amount_decimal: price.unit_amount_decimal,
          display_amount: format_amount(price.unit_amount, price.currency),
          type: price.type,
          recurring: price.recurring,
          metadata: stripe_metadata(price.metadata)
        }
      }
    rescue Stripe::StripeError => e
      Rails.logger.error("[Stripe] retrieve_product_details failed: #{e.message}")
      raise Error, e.message
    end

    def construct_webhook_event(payload:, signature:)
      webhook_secret = ENV.fetch("STRIPE_WEBHOOK_SECRET")
      @provider.construct_event(payload: payload, signature: signature, webhook_secret: webhook_secret)
    rescue KeyError => e
      raise Error, "Missing STRIPE_WEBHOOK_SECRET: #{e.message}"
    rescue Stripe::SignatureVerificationError => e
      raise Error, "Invalid Stripe webhook signature: #{e.message}"
    rescue JSON::ParserError => e
      raise Error, "Invalid webhook payload: #{e.message}"
    end

    def sync_transaction_from_event(event)
      object = event.data.object

      case event.type
      when "checkout.session.completed"
        upsert_transaction_from_checkout_session(object, event_type: event.type)
      when "payment_intent.succeeded", "payment_intent.payment_failed"
        upsert_transaction_from_payment_intent(object, event_type: event.type)
      when "invoice.paid", "invoice.payment_failed"
        upsert_transaction_from_invoice(object, event_type: event.type)
      else
        Rails.logger.info("[Stripe] Ignored event type=#{event.type}")
        nil
      end
    end

    private

    def find_transaction(payment_intent_id:, checkout_session_id:)
      return PaymentTransaction.find_by(stripe_payment_intent_id: payment_intent_id) if payment_intent_id.present?
      return PaymentTransaction.find_by(stripe_checkout_session_id: checkout_session_id) if checkout_session_id.present?

      nil
    end

    def upsert_transaction_from_checkout_session(session, user: nil, event_type: nil)
      attrs = {
        user_id: user&.id,
        provider: "stripe",
        stripe_customer_id: session.customer,
        stripe_checkout_session_id: session.id,
        stripe_payment_intent_id: session.payment_intent,
        amount_cents: session.amount_total,
        currency: session.currency,
        status: session.payment_status || session.status,
        metadata: stripe_metadata(session.metadata),
        raw_payload: session.to_hash,
        last_webhook_event_type: event_type,
        paid_at: (session.payment_status == "paid" ? Time.current : nil)
      }

      transaction = PaymentTransaction.find_or_initialize_by(stripe_checkout_session_id: session.id)
      transaction.assign_attributes(attrs.compact)
      transaction.save!
      transaction
    end

    def upsert_transaction_from_payment_intent(payment_intent, user: nil, event_type: nil)
      attrs = {
        user_id: user&.id,
        provider: "stripe",
        stripe_customer_id: payment_intent.customer,
        stripe_payment_intent_id: payment_intent.id,
        amount_cents: payment_intent.amount,
        currency: payment_intent.currency,
        status: payment_intent.status,
        description: payment_intent.description,
        payment_method_type: Array(payment_intent.payment_method_types).first,
        metadata: stripe_metadata(payment_intent.metadata),
        raw_payload: payment_intent.to_hash,
        last_webhook_event_type: event_type,
        paid_at: (payment_intent.status == "succeeded" ? Time.current : nil)
      }

      transaction = PaymentTransaction.find_or_initialize_by(stripe_payment_intent_id: payment_intent.id)
      transaction.assign_attributes(attrs.compact)
      transaction.save!
      transaction
    end

    def upsert_transaction_from_invoice(invoice, event_type: nil)
      payment_intent_id = invoice.payment_intent
      transaction = if payment_intent_id.present?
        PaymentTransaction.find_or_initialize_by(stripe_payment_intent_id: payment_intent_id)
      else
        PaymentTransaction.find_or_initialize_by(stripe_invoice_id: invoice.id)
      end

      transaction.assign_attributes(
        provider: "stripe",
        stripe_customer_id: invoice.customer,
        stripe_invoice_id: invoice.id,
        amount_cents: invoice.amount_paid.presence || invoice.amount_due,
        currency: invoice.currency,
        status: invoice.status,
        metadata: stripe_metadata(invoice.metadata),
        raw_payload: invoice.to_hash,
        last_webhook_event_type: event_type,
        paid_at: (invoice.status == "paid" ? Time.current : nil)
      )
      transaction.save!
      transaction
    end

    def stripe_metadata(metadata)
      return {} if metadata.blank?

      metadata.respond_to?(:to_hash) ? metadata.to_hash : metadata
    end

    def validate_price_payload!(price:, product_id:, currency:)
      if product_id.present? && price.product.to_s != product_id.to_s
        raise ArgumentError, "price_id does not belong to product_id"
      end

      if currency.present? && price.currency.to_s.downcase != currency.to_s.downcase
        raise ArgumentError, "currency does not match the selected price"
      end
    end

    def format_amount(unit_amount, currency)
      return nil if unit_amount.blank?

      amount = unit_amount.to_f / 100
      "#{format('%.2f', amount)} #{currency.to_s.upcase}"
    end
  end
end
