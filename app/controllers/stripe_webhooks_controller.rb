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
  rescue Payments::WebhookEventProcessor::ProcessingError => e
    render_json_response(
      status_code: 422,
      message: "Webhook processing failed.",
      error: e.message
    )
  end

  private

  def webhook_processor
    @webhook_processor ||= Payments::WebhookEventProcessor.new
  end
end
