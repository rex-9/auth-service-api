class PaymentTransaction < ApplicationRecord
  self.table_name = "payments"

  belongs_to :user, optional: true, inverse_of: :payments

  validates :provider, presence: true
  validates :status, presence: true

  scope :for_customer, ->(customer_id) { where(stripe_customer_id: customer_id) }
  scope :recent_first, -> { order(created_at: :desc) }

  def paid?
    status == "succeeded" || status == "paid"
  end
end
