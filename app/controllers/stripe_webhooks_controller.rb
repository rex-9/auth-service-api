class StripeWebhooksController < ApplicationController
  skip_before_action :enforce_active_platform_session!

  def create
    signature = request.headers["Stripe-Signature"]
    result = webhook_processor.process(raw_payload: request.raw_post, signature: signature)

    render_json_response(
      status_code: 200,
      message: "Webhook processed successfully.",
      data: result
    )
  rescue Payments::WebhookEventProcessor::InvalidRequest => e
    render_json_response(
      status_code: 400,
      message: "Invalid Stripe webhook.",
      error: e.message
    )
  rescue Payments::WebhookEventProcessor::ProcessingError => e
    render_json_response(status_code: 500, message: "Webhook processing failed.", error: e.message)
  end

  private

  def webhook_processor
    @webhook_processor ||= Payments::WebhookEventProcessor.new
  end
end
