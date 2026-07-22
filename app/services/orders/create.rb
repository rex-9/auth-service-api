module Orders
  class Create
    def initialize(provider: Payments::Providers::StripeProvider.new)
      @provider = provider
    end

    def call(user:, resource_id:, quantity: 1)
      quantity = Integer(quantity)
      raise ArgumentError, "quantity must be greater than zero" unless quantity.positive?

      price = @provider.retrieve_price(resource_id)
      raise ArgumentError, "price is inactive" unless price.active
      raise ArgumentError, "price must be a one-time fixed price" unless price.type == "one_time" && price.unit_amount.present?
      product = @provider.retrieve_product(price.product)
      raise ArgumentError, "product is inactive" unless product.active

      unit_price = price.unit_amount.to_i
      subtotal = unit_price * quantity

      Order.transaction do
        order = user.orders.create!(
          status: "pending", payment_status: "unpaid", subtotal_cents: subtotal,
          discount_cents: 0, tax_cents: 0, total_cents: subtotal, currency: price.currency,
          customer_email: user.email, customer_name: user.name
        )
        order.order_items.create!(
          stripe_product_id: product.id, stripe_price_id: price.id, name: product.name,
          unit_price_cents: unit_price, quantity: quantity, total_cents: subtotal,
          metadata: { "stripe_product_metadata" => metadata_hash(product.metadata), "stripe_price_metadata" => metadata_hash(price.metadata) }
        )
        order
      end
    end

    private

    def metadata_hash(metadata)
      metadata.respond_to?(:to_hash) ? metadata.to_hash : {}
    end
  end
end
