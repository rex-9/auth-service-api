# frozen_string_literal: true

# app/constants/payment_constants.rb
module PaymentConstants
  module SubscriptionStatus
    INCOMPLETE         = "incomplete".freeze
    ACTIVE             = "active".freeze
    PAST_DUE           = "past_due".freeze
    CANCELED           = "canceled".freeze
    INCOMPLETE_EXPIRED = "incomplete_expired".freeze
    UNPAID             = "unpaid".freeze
    TRIALING           = "trialing".freeze
    PAUSED             = "paused".freeze
    ALL                = [
      INCOMPLETE, ACTIVE, PAST_DUE, CANCELED,
      INCOMPLETE_EXPIRED, UNPAID, TRIALING, PAUSED
    ].freeze
  end

  module BillingCycle
    MONTH = "month".freeze
    YEAR  = "year".freeze
    ALL   = [ MONTH, YEAR ].freeze
  end

  module PaymentMethodType
    CARD          = "card".freeze
    GOOGLE_PAY    = "google_pay".freeze
    APPLE_PAY     = "apple_pay".freeze
    BANK_TRANSFER = "bank_transfer".freeze
    OTHER         = "other".freeze
    ALL           = [ CARD, GOOGLE_PAY, APPLE_PAY, BANK_TRANSFER, OTHER ].freeze
  end

  module TransactionStatus
    SUCCEEDED               = "succeeded".freeze
    PROCESSING              = "processing".freeze
    REQUIRES_ACTION         = "requires_action".freeze
    REQUIRES_CAPTURE        = "requires_capture".freeze
    REQUIRES_CONFIRMATION   = "requires_confirmation".freeze
    REQUIRES_PAYMENT_METHOD = "requires_payment_method".freeze
    CANCELED                = "canceled".freeze
    ALL                     = [
      SUCCEEDED, PROCESSING, REQUIRES_ACTION, REQUIRES_CAPTURE,
      REQUIRES_CONFIRMATION, REQUIRES_PAYMENT_METHOD, CANCELED
    ].freeze
  end

  module WebhookStatus
    PENDING    = "pending".freeze
    PROCESSING = "processing".freeze
    PROCESSED  = "processed".freeze
    FAILED     = "failed".freeze
    ALL        = [ PENDING, PROCESSING, PROCESSED, FAILED ].freeze
  end

  module StripeEvent
    CHECKOUT_SESSION_COMPLETED = "checkout.session.completed".freeze
    SUBSCRIPTION_UPDATED       = "customer.subscription.updated".freeze
    SUBSCRIPTION_DELETED       = "customer.subscription.deleted".freeze
    SUBSCRIPTION_PAUSED        = "customer.subscription.paused".freeze
    SUBSCRIPTION_RESUMED       = "customer.subscription.resumed".freeze
    PRODUCT_UPDATED            = "product.updated".freeze
    PRICE_CREATED              = "price.created".freeze
    PRICE_UPDATED              = "price.updated".freeze
    PRICE_DELETED              = "price.deleted".freeze

    ALL = [
      CHECKOUT_SESSION_COMPLETED,
      SUBSCRIPTION_UPDATED, SUBSCRIPTION_DELETED,
      SUBSCRIPTION_PAUSED, SUBSCRIPTION_RESUMED,
      PRODUCT_UPDATED,
      PRICE_CREATED, PRICE_UPDATED, PRICE_DELETED
    ].freeze
  end

  module StripeMode
    SUBSCRIPTION = "subscription".freeze
    PAYMENT      = "payment".freeze
  end

  module StripeStatus
    PAID       = "paid".freeze
    PAST_DUE   = "past_due".freeze
    CANCELED   = "canceled".freeze
    REFUNDED   = "refunded".freeze
    OTHER      = "other".freeze
  end
end
