require "rails_helper"

RSpec.describe Payments::CreateStripeCheckoutSession do
  let(:user) { create(:user) }
  let(:order) { Order.create!(user: user, subtotal_cents: 4900, total_cents: 4900, currency: "usd") }
  let(:provider) { instance_double(Payments::Providers::StripeProvider) }
  let(:customers) { instance_double(Payments::FindOrCreateStripeCustomer, call: "cus_test") }

  before do
    order.order_items.create!(stripe_product_id: "prod_test", stripe_price_id: "price_test", name: "Course", unit_price_cents: 4900, quantity: 1)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("FRONTEND_PAYMENT_SUCCESS_URL").and_return("https://app.test/success")
    allow(ENV).to receive(:[]).with("FRONTEND_PAYMENT_CANCEL_URL").and_return("https://app.test/cancel")
  end

  it "creates an attempt from trusted order totals and passes local metadata" do
    expect(provider).to receive(:create_order_checkout_session) do |args|
      expect(args[:metadata]).to include(order_id: order.id, payment_id: kind_of(String))
      expect(args[:idempotency_key]).to start_with("stripe-checkout-payment-")
      OpenStruct.new(id: "cs_test", url: "https://checkout.stripe.test/session")
    end
    result = described_class.new(provider: provider, customer_service: customers).call(user: user, order: order)
    expect(result[:payment]).to have_attributes(amount_cents: 4900, currency: "usd", stripe_checkout_session_id: "cs_test")
  end
end
