class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :stripe_customer_id, :string
    add_index :users, :stripe_customer_id, unique: true

    create_table :payments, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :order, type: :uuid, null: false, foreign_key: true
      t.string :payment_number, null: false
      t.string :provider, null: false, default: "stripe"

      t.string :stripe_customer_id
      t.string :stripe_checkout_session_id
      t.string :stripe_payment_intent_id
      t.string :stripe_invoice_id
      t.string :stripe_charge_id

      t.bigint :amount_cents, null: false
      t.string :currency, null: false
      t.string :status, null: false, default: "pending"
      t.string :payment_method_type
      t.string :description
      t.string :failure_code
      t.text :failure_message
      t.string :last_webhook_event_type
      t.datetime :processing_at
      t.datetime :paid_at
      t.datetime :failed_at
      t.datetime :expired_at
      t.datetime :cancelled_at
      t.datetime :refunded_at
      t.bigint :refunded_amount_cents, null: false, default: 0

      t.jsonb :metadata, null: false, default: {}
      t.jsonb :raw_payload, null: false, default: {}

      t.timestamps
    end

    add_index :payments, :stripe_customer_id
    add_index :payments, :stripe_invoice_id
    add_index :payments, :payment_number, unique: true
    add_index :payments, [ :order_id, :status ]
    add_index :payments, [ :user_id, :created_at ]
    add_index :payments, :stripe_checkout_session_id, unique: true, where: "stripe_checkout_session_id IS NOT NULL", name: "idx_payments_checkout_session"
    add_index :payments, :stripe_payment_intent_id, unique: true, where: "stripe_payment_intent_id IS NOT NULL", name: "idx_payments_payment_intent"
    add_index :payments, :stripe_charge_id, unique: true, where: "stripe_charge_id IS NOT NULL", name: "idx_payments_stripe_charge"

    add_check_constraint :payments, "amount_cents > 0", name: "payments_amount_positive"
    add_check_constraint :payments, "refunded_amount_cents >= 0", name: "payments_refund_nonnegative"
    add_check_constraint :payments, "refunded_amount_cents <= amount_cents", name: "payments_refund_not_excessive"
  end
end
