class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :stripe_customer_id, :string
    add_index :users, :stripe_customer_id, unique: true

    create_table :payments, id: :uuid do |t|
      t.references :user, type: :uuid, null: true, foreign_key: true
      t.string :provider, null: false, default: "stripe"

      t.string :stripe_customer_id
      t.string :stripe_checkout_session_id
      t.string :stripe_payment_intent_id
      t.string :stripe_invoice_id

      t.bigint :amount_cents
      t.string :currency
      t.string :status, null: false, default: "pending"
      t.string :payment_method_type
      t.string :description
      t.string :last_webhook_event_type
      t.datetime :paid_at

      t.jsonb :metadata, null: false, default: {}
      t.jsonb :raw_payload, null: false, default: {}

      t.timestamps
    end

    add_index :payments, :stripe_customer_id
    add_index :payments, :stripe_invoice_id
    add_index :payments, :stripe_checkout_session_id, unique: true, where: "stripe_checkout_session_id IS NOT NULL", name: "idx_payments_checkout_session"
    add_index :payments, :stripe_payment_intent_id, unique: true, where: "stripe_payment_intent_id IS NOT NULL", name: "idx_payments_payment_intent"
  end
end
