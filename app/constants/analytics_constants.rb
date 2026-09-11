# frozen_string_literal: true

# app/constants/analytics_constants.rb
module AnalyticsConstants
  # Shared GA4/Firebase client event contract. Core retains authoritative
  # business facts and does not ingest raw behavioral analytics events.
  module Event
    SIGN_UP             = "sign_up".freeze
    SIGN_IN             = "sign_in".freeze
    SIGN_OUT            = "sign_out".freeze
    BEGIN_ONBOARDING    = "begin_onboarding".freeze
    COMPLETE_ONBOARDING = "complete_onboarding".freeze
    VIEW_PAGE           = "view_page".freeze
    VIEW_PRODUCT        = "view_product".freeze
    PURCHASE_PRODUCT    = "purchase_product".freeze
    OPEN_NOTIFICATION   = "open_notification".freeze
    ALL = [
      SIGN_UP, SIGN_IN, SIGN_OUT, BEGIN_ONBOARDING, COMPLETE_ONBOARDING,
      VIEW_PAGE, VIEW_PRODUCT, PURCHASE_PRODUCT, OPEN_NOTIFICATION
    ].freeze
  end

  module Platform
    WEB     = "web".freeze
    ANDROID = "android".freeze
    IOS     = "ios".freeze
    ALL     = [ WEB, ANDROID, IOS ].freeze
  end

  module Parameter
    PLATFORM        = "platform".freeze
    METHOD          = "method".freeze
    PAGE_PATH       = "page_path".freeze
    PAGE_TITLE      = "page_title".freeze
    PRODUCT_ID      = "product_id".freeze
    PRODUCT_NAME    = "product_name".freeze
    CURRENCY        = "currency".freeze
    UNIT_AMOUNT = "unit_amount".freeze
    PURCHASE_ID       = "purchase_id".freeze
    NOTIFICATION_ID = "notification_id".freeze
  end

  module AuthMethod
    EMAIL  = "email".freeze
    GOOGLE = "google".freeze
    APPLE  = "apple".freeze
    ALL    = [ EMAIL, GOOGLE, APPLE ].freeze
  end

  module Period
    TODAY       = "today".freeze
    YESTERDAY   = "yesterday".freeze
    SEVEN_DAYS  = "7d".freeze
    THIRTY_DAYS = "30d".freeze
    THIS_MONTH  = "this_month".freeze
    LAST_MONTH  = "last_month".freeze
    THIS_YEAR   = "this_year".freeze
    LAST_YEAR   = "last_year".freeze
    CUSTOM      = "custom".freeze
    ALL         = [
      TODAY, YESTERDAY, SEVEN_DAYS, THIRTY_DAYS,
      THIS_MONTH, LAST_MONTH, THIS_YEAR, LAST_YEAR, CUSTOM
    ].freeze
  end

  module Grain
    HOURLY  = "hourly".freeze
    DAILY   = "daily".freeze
    MONTHLY = "monthly".freeze
    ALL     = [ HOURLY, DAILY, MONTHLY ].freeze
  end
end
