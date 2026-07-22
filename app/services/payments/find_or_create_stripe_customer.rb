module Payments
  class FindOrCreateStripeCustomer
    def initialize(provider: Providers::StripeProvider.new)
      @provider = provider
    end

    def call(user:)
      return user.stripe_customer_id if user.stripe_customer_id.present?

      customer = @provider.create_customer(email: user.email, name: user.name, metadata: { user_id: user.id })
      user.with_lock do
        return user.stripe_customer_id if user.reload.stripe_customer_id.present?
        user.update!(stripe_customer_id: customer.id)
      end
      customer.id
    end
  end
end
