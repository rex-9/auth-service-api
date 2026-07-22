Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key).presence || ENV["STRIPE_SECRET_KEY"].presence || ENV["STRIPE_SECRET"].presence
