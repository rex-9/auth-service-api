require "rails_helper"

RSpec.describe Orders::Create do
  let(:user) { create(:user) }
  let(:provider) { instance_double(Payments::Providers::StripeProvider) }
  let(:price) { OpenStruct.new(id: "price_test", product: "prod_test", active: true, type: "one_time", unit_amount: 4900, currency: "usd", metadata: {}) }
  let(:product) { OpenStruct.new(id: "prod_test", active: true, name: "Trusted course", metadata: {}) }

  it "uses the provider catalog values and creates a snapshot" do
    allow(provider).to receive(:retrieve_price).with("price_test").and_return(price)
    allow(provider).to receive(:retrieve_product).with("prod_test").and_return(product)

    order = described_class.new(provider: provider).call(user: user, resource_id: "price_test", quantity: 2)
    expect(order.total_cents).to eq(9800)
    expect(order.order_items.first.attributes).to include("name" => "Trusted course", "unit_price_cents" => 4900, "quantity" => 2)
  end
end
