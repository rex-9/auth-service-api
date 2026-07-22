module Payments
  class WebhookEventProcessor
    class InvalidRequest < StandardError; end
    class ProcessingError < StandardError; end
    SUPPORTED_EVENTS = %w[
      checkout.session.completed checkout.session.async_payment_succeeded
      checkout.session.async_payment_failed checkout.session.expired
      payment_intent.payment_failed charge.refunded
    ].freeze

    def initialize(provider: Providers::StripeProvider.new)
      @provider = provider
    end

    def process(raw_payload:, signature:)
      event = construct_event(raw_payload, signature)
      record = record_event(event)
      return duplicate_response(record) if %w[processed ignored].include?(record.status)

      record.with_lock do
        return duplicate_response(record) if %w[processed ignored].include?(record.status)
        record.update!(status: "processing", attempts: record.attempts + 1, last_attempted_at: Time.current)
      end
      unless SUPPORTED_EVENTS.include?(event.type)
        record.update!(status: "ignored", processed_at: Time.current)
        return { processed: true, ignored: true, stripe_event_id: event.id, event_type: event.type }
      end

      duplicate = false
      PaymentWebhookEvent.transaction do
        record.lock!
        if %w[processed ignored].include?(record.status)
          duplicate = true
        else
          process_supported_event!(record, event)
          record.update!(status: "processed", processed_at: Time.current, error_message: nil)
        end
      end
      return duplicate_response(record) if duplicate
      { processed: true, stripe_event_id: event.id, event_type: event.type }
    rescue InvalidRequest
      raise
    rescue StandardError => e
      Rails.logger.error("[StripeWebhook] Processing failed: #{e.class}: #{e.message}")
      if record&.persisted?
        record.update(
          status: "failed", attempts: [ record.attempts, 1 ].max,
          last_attempted_at: record.last_attempted_at || Time.current,
          error_message: e.message.to_s.first(1_000)
        )
      end
      raise ProcessingError, "Verified Stripe event could not be processed"
    end

    private

    def construct_event(payload, signature)
      secret = Rails.application.credentials.dig(:stripe, :webhook_secret).presence || ENV["STRIPE_WEBHOOK_SECRET"].presence
      raise InvalidRequest, "Stripe signature is missing" if signature.blank?
      raise InvalidRequest, "Stripe webhook secret is not configured" if secret.blank?
      @provider.construct_event(payload: payload, signature: signature, webhook_secret: secret)
    rescue Stripe::SignatureVerificationError, JSON::ParserError => e
      raise InvalidRequest, e.message
    end

    def record_event(event)
      PaymentWebhookEvent.create!(stripe_event_id: event.id, event_type: event.type, payload: event.to_hash, status: "received")
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      PaymentWebhookEvent.find_by!(stripe_event_id: event.id)
    end

    def process_supported_event!(record, event)
      object = event.data.object
      case event.type
      when "checkout.session.completed", "checkout.session.async_payment_succeeded"
        process_checkout!(record, object, event.type, force_paid: event.type.end_with?("async_payment_succeeded"))
      when "checkout.session.async_payment_failed"
        process_checkout_failure!(record, object, event.type)
      when "checkout.session.expired"
        process_expiration!(record, object, event.type)
      when "payment_intent.payment_failed"
        process_intent_failure!(record, object, event.type)
      when "charge.refunded"
        process_refund!(record, object, event.type)
      end
    end

    def process_checkout!(record, session, event_type, force_paid: false)
      payment, order = resolve_checkout!(session)
      payment.lock!; order.lock!
      validate_checkout!(session, payment, order)
      record.update!(payment: payment)

      paid = force_paid || session.payment_status == "paid"
      if paid
        other_paid = order.payments.where.not(id: payment.id).where(status: %w[paid partially_refunded refunded]).exists?
        raise ProcessingError, "Order has already been paid by another payment" if other_paid
        now = Time.current
        payment.transition_to!("paid", checkout_attributes(session, event_type).merge(paid_at: payment.paid_at || now, failure_code: nil, failure_message: nil))
        order.update!(payment_status: "paid", status: order.status == "completed" ? "completed" : "confirmed", paid_at: order.paid_at || now)
      else
        payment.transition_to!("processing", checkout_attributes(session, event_type).merge(processing_at: payment.processing_at || Time.current))
        order.update!(payment_status: "processing") unless %w[paid partially_refunded refunded].include?(order.payment_status)
      end
    end

    def process_checkout_failure!(record, session, event_type)
      payment, order = resolve_checkout!(session)
      payment.lock!; order.lock!; validate_checkout!(session, payment, order); record.update!(payment: payment)
      payment.transition_to!("failed", failed_at: Time.current, last_webhook_event_type: event_type)
      order.update!(payment_status: "failed") unless %w[paid partially_refunded refunded].include?(order.payment_status)
    end

    def process_expiration!(record, session, event_type)
      payment, = resolve_checkout!(session)
      payment.lock!; record.update!(payment: payment)
      return unless %w[pending processing].include?(payment.status)
      payment.transition_to!("expired", expired_at: Time.current, last_webhook_event_type: event_type)
    end

    def process_intent_failure!(record, intent, event_type)
      payment = PaymentTransaction.find_by(stripe_payment_intent_id: intent.id) || PaymentTransaction.find(metadata_value(intent, "payment_id"))
      payment.lock!; record.update!(payment: payment)
      return if payment.paid? || %w[partially_refunded refunded].include?(payment.status)
      error = intent.last_payment_error
      payment.transition_to!("failed", failed_at: Time.current, failure_code: error&.code, failure_message: error&.message.to_s.first(500), last_webhook_event_type: event_type)
      payment.order&.update!(payment_status: "failed") unless %w[paid partially_refunded refunded].include?(payment.order&.payment_status)
    end

    def process_refund!(record, charge, event_type)
      payment = PaymentTransaction.find_by(stripe_charge_id: charge.id) || PaymentTransaction.find_by!(stripe_payment_intent_id: charge.payment_intent)
      payment.lock!; payment.order.lock!; record.update!(payment: payment)
      refunded = charge.amount_refunded.to_i
      status = refunded >= payment.amount_cents ? "refunded" : "partially_refunded"
      payment.transition_to!(status, stripe_charge_id: charge.id, refunded_amount_cents: refunded, refunded_at: Time.current, last_webhook_event_type: event_type)
      payment.order.update!(payment_status: status)
    end

    def resolve_checkout!(session)
      payment = PaymentTransaction.find(metadata_value(session, "payment_id"))
      order = Order.find(metadata_value(session, "order_id"))
      [ payment, order ]
    end

    def validate_checkout!(session, payment, order)
      raise ProcessingError, "Payment does not belong to order" unless payment.order_id == order.id
      raise ProcessingError, "Payment amount does not match order" unless payment.amount_cents == order.total_cents
      raise ProcessingError, "Payment currency does not match order" unless payment.currency == order.currency
      raise ProcessingError, "Checkout Session does not match payment" unless payment.stripe_checkout_session_id == session.id
      raise ProcessingError, "Stripe amount does not match payment" unless session.amount_total.to_i == payment.amount_cents
      raise ProcessingError, "Stripe currency does not match payment" unless session.currency.to_s.downcase == payment.currency
      raise ProcessingError, "Stripe customer does not match payment" if payment.stripe_customer_id.present? && session.customer.to_s != payment.stripe_customer_id
      raise ProcessingError, "Order metadata mismatch" unless metadata_value(session, "order_id") == order.id
      raise ProcessingError, "Payment metadata mismatch" unless metadata_value(session, "payment_id") == payment.id
    end

    def checkout_attributes(session, event_type)
      {
        stripe_customer_id: session.customer, stripe_checkout_session_id: session.id,
        stripe_payment_intent_id: session.payment_intent,
        payment_method_type: Array(session.payment_method_types).first,
        last_webhook_event_type: event_type
      }.compact
    end

    def metadata_value(object, key)
      metadata = object.metadata.respond_to?(:to_hash) ? object.metadata.to_hash : object.metadata
      metadata[key] || metadata[key.to_sym]
    end

    def duplicate_response(record)
      { processed: true, duplicate: true, stripe_event_id: record.stripe_event_id, event_type: record.event_type }
    end
  end
end
