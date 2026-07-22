class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items, id: :uuid do |t|
      t.references :order, type: :uuid, null: false, foreign_key: true
      t.string :stripe_product_id, null: false
      t.string :stripe_price_id, null: false
      t.string :name, null: false
      t.bigint :unit_price_cents, null: false
      t.integer :quantity, null: false, default: 1
      t.bigint :total_cents, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :order_items, :stripe_product_id
    add_index :order_items, :stripe_price_id
    add_check_constraint :order_items, "unit_price_cents >= 0", name: "order_items_price_nonnegative"
    add_check_constraint :order_items, "quantity > 0", name: "order_items_quantity_positive"
    add_check_constraint :order_items, "total_cents >= 0", name: "order_items_total_nonnegative"
  end
end
