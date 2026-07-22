class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string :order_number, null: false
      t.string :status, null: false, default: "pending"
      t.string :payment_status, null: false, default: "unpaid"
      t.bigint :subtotal_cents, null: false, default: 0
      t.bigint :discount_cents, null: false, default: 0
      t.bigint :tax_cents, null: false, default: 0
      t.bigint :total_cents, null: false
      t.string :currency, null: false
      t.string :customer_email
      t.string :customer_name
      t.datetime :paid_at
      t.datetime :cancelled_at
      t.datetime :completed_at
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :orders, :order_number, unique: true
    add_index :orders, :status
    add_index :orders, :payment_status
    add_index :orders, [ :user_id, :created_at ]
    add_check_constraint :orders, "subtotal_cents >= 0", name: "orders_subtotal_nonnegative"
    add_check_constraint :orders, "discount_cents >= 0", name: "orders_discount_nonnegative"
    add_check_constraint :orders, "tax_cents >= 0", name: "orders_tax_nonnegative"
    add_check_constraint :orders, "total_cents >= 0", name: "orders_total_nonnegative"
  end
end
