require "rails_helper"

RSpec.describe Payments::WebhookEventProcessor do
  let(:user) { create(:user) }
  let(:order) { Order.create!(user: user, subtotal_cents: 4900, total_cents: 4900, currency: "usd") }
  let(:payment) do
    PaymentTransaction.create!(
      user: user, order: order, amount_cents: 4900, currency: "usd",
      stripe_customer_id: "cus_test", stripe_checkout_session_id: "cs_test"
    )
  end
  let(:provider) { instance_double(Payments::Providers::StripeProvider) }
  let(:processor) { described_class.new(provider: provider) }

  before { allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhook_secret).and_return("whsec_test") }

  it "marks a validated paid checkout and its order paid exactly once" do
    event = checkout_event("evt_paid", payment_status: "paid")
    allow(provider).to receive(:construct_event).and_return(event)

    expect(processor.process(raw_payload: "raw", signature: "sig")).to include(processed: true)
    expect(payment.reload).to have_attributes(status: "paid", stripe_payment_intent_id: "pi_test", last_webhook_event_type: "checkout.session.completed")
    expect(order.reload).to have_attributes(status: "confirmed", payment_status: "paid")
    paid_at = payment.paid_at
    expect(processor.process(raw_payload: "raw", signature: "sig")).to include(duplicate: true)
    expect(payment.reload.paid_at).to eq(paid_at)
  end

  it "keeps delayed payment methods in processing" do
    allow(provider).to receive(:construct_event).and_return(checkout_event("evt_delayed", payment_status: "unpaid"))
    processor.process(raw_payload: "raw", signature: "sig")
    expect(payment.reload.status).to eq("processing")
    expect(order.reload.payment_status).to eq("processing")
  end

  it "records unsupported verified events as ignored" do
    event = OpenStruct.new(id: "evt_other", type: "customer.updated", data: OpenStruct.new(object: OpenStruct.new), to_hash: { id: "evt_other" })
    allow(provider).to receive(:construct_event).and_return(event)
    expect(processor.process(raw_payload: "raw", signature: "sig")).to include(ignored: true)
    expect(PaymentWebhookEvent.find_by!(stripe_event_id: "evt_other").status).to eq("ignored")
  end

  it "rejects a checkout amount mismatch without paying the order" do
    event = checkout_event("evt_wrong", payment_status: "paid")
    event.data.object.amount_total = 1
    allow(provider).to receive(:construct_event).and_return(event)
    expect { processor.process(raw_payload: "raw", signature: "sig") }.to raise_error(described_class::ProcessingError)
    expect(payment.reload.status).to eq("pending")
    expect(order.reload.payment_status).to eq("unpaid")
    expect(PaymentWebhookEvent.find_by!(stripe_event_id: "evt_wrong")).to have_attributes(status: "failed", attempts: 1)
  end

  private

  def checkout_event(id, payment_status:)
    session = OpenStruct.new(
      id: "cs_test", customer: "cus_test", payment_intent: "pi_test",
      payment_status: payment_status, payment_method_types: [ "card" ],
      amount_total: 4900, currency: "usd",
      metadata: { "payment_id" => payment.id, "order_id" => order.id }
    )
    OpenStruct.new(
      id: id, type: "checkout.session.completed", data: OpenStruct.new(object: session),
      to_hash: { id: id, type: "checkout.session.completed" }
    )
  end
end
