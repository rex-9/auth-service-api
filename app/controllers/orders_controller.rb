class OrdersController < ApplicationController
  before_action :authenticate_user!

  def create
    order = Orders::Create.new.call(user: current_user, resource_id: params.require(:resource_id), quantity: params[:quantity] || 1)
    render_json_response(status_code: 201, message: "Order created successfully.", data: { order: OrderSerializer.call(order) })
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    render_json_response(status_code: 422, message: "Invalid order payload.", error: e.message)
  rescue Stripe::StripeError
    render_json_response(status_code: 422, message: "Unable to load the selected item.", error: "The selected item is unavailable")
  end

  def show
    order = current_user.orders.includes(:order_items).find(params[:id])
    render_json_response(status_code: 200, message: "Order fetched successfully.", data: { order: OrderSerializer.call(order) })
  rescue ActiveRecord::RecordNotFound
    render_json_response(status_code: 404, message: "Order not found.")
  end

  def checkout
    order = current_user.orders.includes(:order_items).find(params[:order_id])
    result = Payments::CreateStripeCheckoutSession.new.call(user: current_user, order: order)
    render_json_response(status_code: 201, message: "Checkout session created successfully.", data: {
      order: OrderSerializer.call(result[:order]), payment: PaymentSerializer.call(result[:payment]), checkout_url: result[:checkout_url]
    })
  rescue ActiveRecord::RecordNotFound
    render_json_response(status_code: 404, message: "Order not found.")
  rescue Payments::CreateStripeCheckoutSession::Error, ActiveRecord::RecordInvalid => e
    render_json_response(status_code: 422, message: "Failed to create checkout session.", error: e.message)
  end
end
