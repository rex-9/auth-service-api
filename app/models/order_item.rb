class OrderItem < ApplicationRecord
  belongs_to :order

  before_validation :calculate_total

  validates :stripe_product_id, :stripe_price_id, :name, presence: true
  validates :unit_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :total_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  private

  def calculate_total
    self.total_cents = unit_price_cents * quantity if unit_price_cents.present? && quantity.present?
  end
end
