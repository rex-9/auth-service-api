class PaymentTransaction < ApplicationRecord
  self.table_name = "payments"

  belongs_to :user, optional: true, inverse_of: :payments
  belongs_to :order, optional: true, inverse_of: :payments
  has_many :payment_webhook_events, foreign_key: :payment_id, dependent: :nullify, inverse_of: :payment

  STATUSES = %w[pending processing paid failed expired cancelled partially_refunded refunded].freeze
  TERMINAL_STATUSES = %w[paid partially_refunded refunded].freeze

  before_validation :normalize_currency
  before_validation :assign_payment_number, on: :create, if: :order_id?

  validates :provider, presence: true
  validates :status, inclusion: { in: STATUSES }, if: :order_id?
  validates :payment_number, presence: true, uniqueness: true, if: :order_id?
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }, if: :order_id?
  validates :currency, presence: true, if: :order_id?
  validate :order_and_user_match

  scope :for_customer, ->(customer_id) { where(stripe_customer_id: customer_id) }
  scope :recent_first, -> { order(created_at: :desc) }

  def paid?
    status == "succeeded" || status == "paid"
  end

  def transition_to!(new_status, attributes = {})
    new_status = new_status.to_s
    return self if status == new_status
    return self if TERMINAL_STATUSES.include?(status) && !allowed_terminal_transition?(new_status)

    update!(attributes.merge(status: new_status))
  end

  private

  def normalize_currency
    self.currency = currency.to_s.downcase.presence
  end

  def assign_payment_number
    self.payment_number ||= "PAY-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end

  def order_and_user_match
    errors.add(:user, "must own the order") if order && user_id != order.user_id
  end

  def allowed_terminal_transition?(new_status)
    (status == "paid" && %w[partially_refunded refunded].include?(new_status)) ||
      (status == "partially_refunded" && new_status == "refunded")
  end
end
