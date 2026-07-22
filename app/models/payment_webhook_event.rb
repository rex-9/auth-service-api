class PaymentWebhookEvent < ApplicationRecord
  STATUSES = %w[received processing processed failed ignored].freeze
  belongs_to :payment, class_name: "PaymentTransaction", optional: true, inverse_of: :payment_webhook_events

  validates :stripe_event_id, presence: true, uniqueness: true
  validates :event_type, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :processed, -> { where(status: "processed") }
end
