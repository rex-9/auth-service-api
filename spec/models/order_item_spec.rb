require "rails_helper"

RSpec.describe OrderItem, type: :model do
  it "calculates its immutable purchase total from integer inputs" do
    item = described_class.new(unit_price_cents: 1_250, quantity: 2)
    item.valid?
    expect(item.total_cents).to eq(2_500)
  end

  it "rejects non-positive quantities" do
    item = described_class.new(quantity: 0)
    item.valid?
    expect(item.errors[:quantity]).to be_present
  end
end
