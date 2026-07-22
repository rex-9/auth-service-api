require "rails_helper"

RSpec.describe PaymentTransaction, type: :model do
  let(:user) { create(:user) }
  let(:order) { Order.create!(user: user, subtotal_cents: 500, total_cents: 500, currency: "usd") }

  it "generates a payment number and normalizes currency" do
    payment = described_class.create!(user: user, order: order, amount_cents: 500, currency: "USD")
    expect(payment.payment_number).to match(/\APAY-\d{8}-[A-F0-9]{8}\z/)
    expect(payment.currency).to eq("usd")
  end

  it "does not downgrade a paid payment" do
    payment = described_class.create!(user: user, order: order, amount_cents: 500, currency: "usd", status: "paid")
    payment.transition_to!("failed", failed_at: Time.current)
    expect(payment.reload.status).to eq("paid")
  end
end
