class PaymentSerializer
  def self.call(payment)
    {
      id: payment.id, payment_number: payment.payment_number, provider: payment.provider,
      status: payment.status, amount_cents: payment.amount_cents, currency: payment.currency,
      payment_method_type: payment.payment_method_type, paid_at: payment.paid_at,
      failed_at: payment.failed_at, created_at: payment.created_at
    }
  end
end
