class PaymentsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [ :get_product_details ]
  skip_before_action :enforce_active_platform_session!, only: [ :get_product_details ]

  def create_checkout_session
    dto = Payments::Dto::CreateCheckoutSessionDto.new(
      customer_id: params[:customer_id],
      amount_cents: params[:amount_cents],
      currency: params[:currency],
      success_url: params[:success_url],
      cancel_url: params[:cancel_url],
      description: params[:description],
      metadata: params[:metadata]
    )

    session = stripe_service.create_checkout_session(dto: dto, user: current_user)

    render_json_response(
      status_code: 201,
      message: "Checkout session created successfully.",
      data: {
        checkout_session_id: session.id,
        url: session.url,
        status: session.status,
        payment_status: session.payment_status
      }
    )
  rescue ArgumentError => e
    render_json_response(status_code: 422, message: "Invalid checkout payload.", error: e.message)
  rescue Payments::StripeService::Error => e
    render_json_response(status_code: 422, message: "Failed to create checkout session.", error: e.message)
  end

  def create_payment_intent
    payload = payment_payload

    payment_intent = if payload[:amount_cents].present?
      dto = Payments::Dto::CreatePaymentIntentDto.new(
        customer_id: payload[:customer_id],
        amount_cents: payload[:amount_cents],
        currency: payload[:currency],
        description: payload[:description],
        metadata: payload[:metadata],
        payment_method_types: payload[:payment_method_types].presence || [ payload[:payment_method_type] ].compact
      )

      stripe_service.create_payment_intent(dto: dto, user: current_user)
    else
      stripe_service.create_payment_intent_from_price_payload(payload: payload, user: current_user)
    end

    render_json_response(
      status_code: 201,
      message: "Payment intent created successfully.",
      data: {
        payment_intent_id: payment_intent.id,
        client_secret: payment_intent.client_secret,
        status: payment_intent.status
      }
    )
  rescue ArgumentError => e
    render_json_response(status_code: 422, message: "Invalid payment intent payload.", error: e.message)
  rescue Payments::StripeService::Error => e
    render_json_response(status_code: 422, message: "Failed to create payment intent.", error: e.message)
  end

  def verify_payment_status
    result = stripe_service.verify_payment_status(payment_intent_id: params[:payment_intent_id])
    render_json_response(status_code: 200, message: "Payment status fetched successfully.", data: result)
  rescue Payments::StripeService::Error => e
    render_json_response(status_code: 422, message: "Failed to verify payment status.", error: e.message)
  end

  def show_payment_details
    transaction = stripe_service.retrieve_payment_details(
      payment_intent_id: params[:payment_intent_id],
      checkout_session_id: params[:checkout_session_id]
    )

    render_json_response(
      status_code: 200,
      message: "Payment details fetched successfully.",
      data: { payment: serialize_transaction(transaction) }
    )
  rescue Payments::StripeService::Error => e
    render_json_response(status_code: 422, message: "Failed to fetch payment details.", error: e.message)
  end

  def list_customer_payments
    customer_id = params[:customer_id]
    payments = stripe_service.list_customer_payments(customer_id: customer_id, limit: params[:limit].to_i.positive? ? params[:limit].to_i : 20)

    render_json_response(
      status_code: 200,
      message: "Customer payments fetched successfully.",
      data: { payments: payments.map { |payment| serialize_transaction(payment) } }
    )
  rescue Payments::StripeService::Error => e
    render_json_response(status_code: 422, message: "Failed to list customer payments.", error: e.message)
  end

  def get_product_details
    payload = payment_payload
    result = stripe_service.retrieve_product_details(
      product_id: payload[:product_id],
      price_id: payload[:price_id]
    )

    render_json_response(
      status_code: 200,
      message: "Product details fetched successfully.",
      data: result
    )
  rescue ArgumentError => e
    render_json_response(status_code: 422, message: "Invalid product details payload.", error: e.message)
  rescue Payments::StripeService::Error => e
    render_json_response(status_code: 422, message: "Failed to fetch product details.", error: e.message)
  end

  private

  def stripe_service
    @stripe_service ||= Payments::StripeService.new
  end

  def payment_payload
    raw = params[:payment].presence || params
    raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h.deep_symbolize_keys : raw.deep_symbolize_keys
  end

  def serialize_transaction(transaction)
    {
      id: transaction.id,
      provider: transaction.provider,
      status: transaction.status,
      amount_cents: transaction.amount_cents,
      currency: transaction.currency,
      customer_id: transaction.stripe_customer_id,
      payment_intent_id: transaction.stripe_payment_intent_id,
      checkout_session_id: transaction.stripe_checkout_session_id,
      invoice_id: transaction.stripe_invoice_id,
      payment_method_type: transaction.payment_method_type,
      description: transaction.description,
      metadata: transaction.metadata,
      last_webhook_event_type: transaction.last_webhook_event_type,
      paid_at: transaction.paid_at,
      created_at: transaction.created_at,
      updated_at: transaction.updated_at
    }
  end
end
