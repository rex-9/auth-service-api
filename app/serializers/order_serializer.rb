class OrderSerializer
  def self.call(order)
    {
      id: order.id, order_number: order.order_number, status: order.status,
      payment_status: order.payment_status, subtotal_cents: order.subtotal_cents,
      discount_cents: order.discount_cents, tax_cents: order.tax_cents,
      total_cents: order.total_cents, currency: order.currency, paid_at: order.paid_at,
      created_at: order.created_at,
      order_items: order.order_items.map { |item| {
        id: item.id, name: item.name, unit_price_cents: item.unit_price_cents,
        quantity: item.quantity, total_cents: item.total_cents
      } }
    }
  end
end
