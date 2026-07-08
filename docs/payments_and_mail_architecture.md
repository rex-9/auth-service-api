# Mail and Stripe Architecture

## 1) Mail service architecture

### Overview
- Action Mailer now uses a custom delivery adapter: `:provider_mail`.
- Existing Devise auth flows (`send_confirmation_instructions`, `send_reset_password_instructions`) are unchanged.
- Provider selection is done by environment variable:
  - `MAIL_MAILER=resend` or `MAIL_MAILER=postmark`
  - optional fallback chain: `MAIL_FALLBACK_MAILERS=postmark,resend`

### Components
- `Mailers::MailMessage`: adapter DTO from `Mail::Message`.
- `Mailers::MailService`: provider orchestrator with fallback sequence.
- `Mailers::ProviderRegistry`: resolves providers from configuration.
- `Mailers::DeliveryMethod`: Action Mailer adapter entrypoint.
- `MailProviders::ResendMailProvider`: isolated Resend HTTP integration.
- `MailProviders::PostmarkMailProvider`: isolated Postmark HTTP integration.

### Example behavior
1. Devise creates email via existing templates.
2. Action Mailer calls `Mailers::DeliveryMethod#deliver!`.
3. Delivery method converts to `Mailers::MailMessage`.
4. `Mailers::MailService` delivers through configured provider.
5. If provider fails and fallback is configured, the next provider is tried.

## 2) Stripe integration

### Components
- `Payments::StripeService`: application service (controllers depend on this only).
- `Payments::Providers::StripeProvider`: wraps Stripe SDK calls.
- DTOs:
  - `Payments::DTO::CreateCheckoutSessionDTO`
  - `Payments::DTO::CreatePaymentIntentDTO`
- `Payments::WebhookEventProcessor`: signature validation + idempotent processing.

### Database
- `payment_transactions`
  - stores Stripe transaction identifiers, status, amount/currency, metadata, payload snapshots.
- `payment_webhook_events`
  - stores Stripe event ids and processing state for idempotency.

### Endpoints
- `POST /payments/checkout_sessions`
- `POST /payments/payment_intents`
- `GET /payments/status?payment_intent_id=pi_xxx`
- `GET /payments/details?payment_intent_id=pi_xxx`
- `GET /payments/details?checkout_session_id=cs_xxx`
- `GET /payments/customers/:customer_id?limit=20`
- `POST /payments/webhooks/stripe`

### Webhook events handled
- `checkout.session.completed`
- `payment_intent.succeeded`
- `payment_intent.payment_failed`
- `invoice.paid`
- `invoice.payment_failed`

### Idempotency strategy
- Verify webhook signature with `STRIPE_WEBHOOK_SECRET`.
- Upsert `payment_webhook_events` by unique `stripe_event_id`.
- Skip already-processed events.
- Process new events inside transaction with row lock.

## 3) Request examples

### Create Checkout Session
```bash
curl -X POST http://localhost:3000/payments/checkout_sessions \
  -H "Authorization: Bearer <jwt>" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "cus_123",
    "amount_cents": 1999,
    "currency": "usd",
    "success_url": "http://localhost:4002/payments/success",
    "cancel_url": "http://localhost:4002/payments/cancel",
    "description": "Pro plan"
  }'
```

### Create Payment Intent
```bash
curl -X POST http://localhost:3000/payments/payment_intents \
  -H "Authorization: Bearer <jwt>" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "cus_123",
    "amount_cents": 1999,
    "currency": "usd",
    "description": "Pro plan",
    "payment_method_types": ["card"]
  }'
```

### Verify payment status
```bash
curl "http://localhost:3000/payments/status?payment_intent_id=pi_123" \
  -H "Authorization: Bearer <jwt>"
```

### Stripe webhook
Configure Stripe CLI or dashboard webhook URL:
- `http://localhost:3000/payments/webhooks/stripe`

## 4) Error handling strategy
- Controllers rescue and return consistent JSON responses.
- Stripe and mail provider failures are logged with context.
- Service layer raises domain errors (`Payments::StripeService::Error`, `Mailers::MailService::DeliveryError`).

## 5) Testing approach
- Unit tests:
  - DTO validation.
  - `Payments::StripeService` behavior with mocked provider.
  - `Mailers::MailService` fallback behavior.
- Request tests:
  - payment endpoints success and validation failures.
  - webhook signature invalid/valid/idempotent processing paths.
- Model tests:
  - uniqueness on webhook event ids.
  - payment transaction query scopes.
