# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_09_092000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "uuid-ossp"

  create_table "assets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "extension"
    t.string "format", null: false
    t.string "name", null: false
    t.uuid "record_id"
    t.string "record_type"
    t.bigint "size", null: false
    t.string "source", default: "upload", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.uuid "user_id"
    t.index ["name"], name: "index_assets_on_name", unique: true
    t.index ["record_type", "record_id"], name: "index_assets_on_record"
    t.index ["url"], name: "index_assets_on_url", unique: true
    t.index ["user_id"], name: "index_assets_on_user_id"
  end

  create_table "order_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.uuid "order_id", null: false
    t.integer "quantity", default: 1, null: false
    t.string "stripe_price_id", null: false
    t.string "stripe_product_id", null: false
    t.bigint "total_cents", null: false
    t.bigint "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["stripe_price_id"], name: "index_order_items_on_stripe_price_id"
    t.index ["stripe_product_id"], name: "index_order_items_on_stripe_product_id"
    t.check_constraint "quantity > 0", name: "order_items_quantity_positive"
    t.check_constraint "total_cents >= 0", name: "order_items_total_nonnegative"
    t.check_constraint "unit_price_cents >= 0", name: "order_items_price_nonnegative"
  end

  create_table "orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "cancelled_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.string "customer_email"
    t.string "customer_name"
    t.bigint "discount_cents", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "order_number", null: false
    t.datetime "paid_at"
    t.string "payment_status", default: "unpaid", null: false
    t.string "status", default: "pending", null: false
    t.bigint "subtotal_cents", default: 0, null: false
    t.bigint "tax_cents", default: 0, null: false
    t.bigint "total_cents", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["payment_status"], name: "index_orders_on_payment_status"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id", "created_at"], name: "index_orders_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "discount_cents >= 0", name: "orders_discount_nonnegative"
    t.check_constraint "subtotal_cents >= 0", name: "orders_subtotal_nonnegative"
    t.check_constraint "tax_cents >= 0", name: "orders_tax_nonnegative"
    t.check_constraint "total_cents >= 0", name: "orders_total_nonnegative"
  end

  create_table "payment_webhook_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "event_type", null: false
    t.datetime "last_attempted_at"
    t.jsonb "payload", default: {}, null: false
    t.uuid "payment_id"
    t.datetime "processed_at"
    t.string "provider", default: "stripe", null: false
    t.string "status", default: "received", null: false
    t.string "stripe_event_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_payment_webhook_events_on_event_type"
    t.index ["payment_id"], name: "index_payment_webhook_events_on_payment_id"
    t.index ["status", "created_at"], name: "index_payment_webhook_events_on_status_and_created_at"
    t.index ["status"], name: "index_payment_webhook_events_on_status"
    t.index ["stripe_event_id"], name: "index_payment_webhook_events_on_stripe_event_id", unique: true
  end

  create_table "payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "amount_cents"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.string "currency"
    t.string "description"
    t.datetime "expired_at"
    t.datetime "failed_at"
    t.string "failure_code"
    t.text "failure_message"
    t.string "last_webhook_event_type"
    t.jsonb "metadata", default: {}, null: false
    t.uuid "order_id"
    t.datetime "paid_at"
    t.string "payment_method_type"
    t.string "payment_number"
    t.datetime "processing_at"
    t.string "provider", default: "stripe", null: false
    t.jsonb "raw_payload", default: {}, null: false
    t.bigint "refunded_amount_cents", default: 0, null: false
    t.datetime "refunded_at"
    t.string "status", default: "pending", null: false
    t.string "stripe_charge_id"
    t.string "stripe_checkout_session_id"
    t.string "stripe_customer_id"
    t.string "stripe_invoice_id"
    t.string "stripe_payment_intent_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["order_id", "status"], name: "index_payments_on_order_id_and_status"
    t.index ["order_id"], name: "index_payments_on_order_id"
    t.index ["payment_number"], name: "index_payments_on_payment_number", unique: true
    t.index ["stripe_charge_id"], name: "index_payments_on_stripe_charge_id", unique: true, where: "(stripe_charge_id IS NOT NULL)"
    t.index ["stripe_checkout_session_id"], name: "idx_payments_checkout_session", unique: true, where: "(stripe_checkout_session_id IS NOT NULL)"
    t.index ["stripe_customer_id"], name: "index_payments_on_stripe_customer_id"
    t.index ["stripe_invoice_id"], name: "index_payments_on_stripe_invoice_id"
    t.index ["stripe_payment_intent_id"], name: "idx_payments_payment_intent", unique: true, where: "(stripe_payment_intent_id IS NOT NULL)"
    t.index ["user_id", "created_at"], name: "index_payments_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_payments_on_user_id"
    t.check_constraint "amount_cents IS NULL OR amount_cents > 0", name: "payments_amount_positive"
    t.check_constraint "amount_cents IS NULL OR refunded_amount_cents <= amount_cents", name: "payments_refund_not_excessive"
    t.check_constraint "refunded_amount_cents >= 0", name: "payments_refund_nonnegative"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "confirmation_code"
    t.datetime "confirmation_code_sent_at"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "jti", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.string "name"
    t.string "photo"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "stripe_customer_id"
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "assets", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "users"
  add_foreign_key "payment_webhook_events", "payments"
  add_foreign_key "payments", "orders"
  add_foreign_key "payments", "users"
end
