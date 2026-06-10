module Payments
  class WebhookEventProcessor
    class ProcessingError < StandardError; end

    def initialize(stripe_service: StripeService.new)
      @stripe_service = stripe_service
    end

    def process(raw_payload:, signature:)
      event = @stripe_service.construct_webhook_event(payload: raw_payload, signature: signature)

      record = PaymentWebhookEvent.find_or_initialize_by(stripe_event_id: event.id)
      record.event_type = event.type
      record.payload = event.to_hash
      record.status = "processing" if record.new_record? || record.status == "received"
      record.save!

      return already_processed_response(record) if record.status == "processed"

      response = nil
      PaymentWebhookEvent.transaction do
        record.lock!
        if record.status == "processed"
          response = already_processed_response(record)
          next
        end

        @stripe_service.sync_transaction_from_event(event)
        record.update!(status: "processed", processed_at: Time.current, error_message: nil)
        response = { processed: true, stripe_event_id: event.id, event_type: event.type }
      end

      response
    rescue StandardError => e
      Rails.logger.error("[StripeWebhook] Processing failed: #{e.message}")
      record&.update(status: "failed", error_message: e.message) if record&.persisted?
      raise ProcessingError, e.message
    end

    private

    def already_processed_response(record)
      {
        processed: true,
        duplicate: true,
        stripe_event_id: record.stripe_event_id,
        event_type: record.event_type
      }
    end
  end
end
