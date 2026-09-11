require "rails_helper"

RSpec.describe "Admin payment records", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:token) { jwt_for(admin) }
  let(:headers) { authorization_headers(token) }

  before do
    allow(CacheService).to receive(:read).and_return(token)
    allow(CacheService).to receive(:write)
  end

  describe "transactions" do
    before { grant_admin_permissions(admin, "transactions", :read) }

    it "lists transactions across users and exposes admin display fields" do
      transaction = create(:payment_transaction)

      get "/v1/admin/payment/transactions", headers: headers

      expect(response).to have_http_status(:ok)
      attributes = response_data.first.fetch("attributes")
      expect(attributes.fetch("id")).to eq(transaction.id)
      expect(attributes.fetch("user_email")).to eq(transaction.user.email)
      expect(attributes.fetch("product_name")).to eq(transaction.product.name)
    end

    it "shows a transaction" do
      transaction = create(:payment_transaction)

      get "/v1/admin/payment/transactions/#{transaction.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response_data.dig("attributes", "id")).to eq(transaction.id)
    end
  end

  describe "subscriptions" do
    before { grant_admin_permissions(admin, "subscriptions", :read) }

    it "filters subscriptions by status and interval" do
      expected = create(:payment_subscription, status: "active", interval: "month")
      create(:payment_subscription, status: "canceled", interval: "year")

      get "/v1/admin/payment/subscriptions",
          params: { status: "active", interval: "month" },
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(response_data.map { |item| item.dig("attributes", "id") }).to eq([ expected.id ])
    end

    it "shows a subscription" do
      subscription = create(:payment_subscription)

      get "/v1/admin/payment/subscriptions/#{subscription.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response_data.dig("attributes", "id")).to eq(subscription.id)
    end
  end

  it "requires matching admin read permission" do
    get "/v1/admin/payment/transactions", headers: headers
    expect(response).to have_http_status(:forbidden)

    get "/v1/admin/payment/subscriptions", headers: headers
    expect(response).to have_http_status(:forbidden)
  end
end
