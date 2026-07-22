class Order < ApplicationRecord
  STATUSES = %w[pending confirmed processing completed cancelled].freeze
  PAYMENT_STATUSES = %w[unpaid processing paid partially_refunded refunded failed].freeze

  belongs_to :user
  has_many :order_items, dependent: :restrict_with_error
  has_many :payments, class_name: "PaymentTransaction", dependent: :restrict_with_error, inverse_of: :order

  before_validation :normalize_currency
  before_validation :assign_order_number, on: :create

  validates :order_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES }
  validates :currency, presence: true
  validates :subtotal_cents, :discount_cents, :tax_cents, :total_cents,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :total_matches_components

  def payable?
    !%w[paid partially_refunded refunded].include?(payment_status) && status != "cancelled" && total_cents.positive?
  end

  def recalculate_totals!
    subtotal = order_items.sum(:total_cents)
    update!(subtotal_cents: subtotal, total_cents: subtotal - discount_cents + tax_cents)
  end

  private

  def normalize_currency
    self.currency = currency.to_s.downcase.presence
  end

  def assign_order_number
    self.order_number ||= "ORD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end

  def total_matches_components
    return if [ subtotal_cents, discount_cents, tax_cents, total_cents ].any?(&:nil?)
    errors.add(:total_cents, "must equal subtotal minus discount plus tax") unless total_cents == subtotal_cents - discount_cents + tax_cents
  end
end
