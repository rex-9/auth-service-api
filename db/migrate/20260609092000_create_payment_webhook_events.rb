class CreatePaymentWebhookEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_webhook_events, id: :uuid do |t|
      t.references :payment, type: :uuid, null: true, foreign_key: { to_table: :payments }
      t.string :provider, null: false, default: "stripe"
      t.string :stripe_event_id, null: false
      t.string :event_type, null: false
      t.string :status, null: false, default: "received"
      t.integer :attempts, null: false, default: 0
      t.datetime :last_attempted_at
      t.datetime :processed_at
      t.text :error_message
      t.jsonb :payload, null: false, default: {}

      t.timestamps
    end

    add_index :payment_webhook_events, :stripe_event_id, unique: true
    add_index :payment_webhook_events, :event_type
    add_index :payment_webhook_events, :status
    add_index :payment_webhook_events, [ :status, :created_at ]
  end
end
