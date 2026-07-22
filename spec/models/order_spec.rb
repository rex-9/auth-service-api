require "rails_helper"

RSpec.describe Order, type: :model do
  let(:user) { create(:user) }

  it "generates a customer-facing number and normalizes currency" do
    order = described_class.create!(user: user, total_cents: 100, subtotal_cents: 100, currency: "USD")
    expect(order.order_number).to match(/\AORD-\d{8}-[A-F0-9]{8}\z/)
    expect(order.currency).to eq("usd")
  end

  it "keeps fulfillment and payment statuses independent" do
    order = described_class.new(user: user, subtotal_cents: 100, total_cents: 100, currency: "usd", status: "processing", payment_status: "paid")
    expect(order).to be_valid
  end

  it "rejects inconsistent totals" do
    order = described_class.new(user: user, subtotal_cents: 100, discount_cents: 10, tax_cents: 0, total_cents: 100, currency: "usd")
    expect(order).not_to be_valid
  end
end
