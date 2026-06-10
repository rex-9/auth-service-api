class PaymentWebhookEvent < ApplicationRecord
  validates :stripe_event_id, presence: true, uniqueness: true
  validates :event_type, presence: true
  validates :status, presence: true

  scope :processed, -> { where(status: "processed") }
end
