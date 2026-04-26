class CreateProductLots < ActiveRecord::Migration[8.1]
  def change
    create_table :product_lots do |t|
      t.bigint  :product_id,         null: false
      t.bigint  :purchase_order_id,  null: false
      t.string  :lot_number,         null: false
      t.date    :received_date,      null: false
      t.decimal :original_quantity,  precision: 12, scale: 2, null: false
      t.decimal :remaining_quantity, precision: 12, scale: 2, null: false
      t.decimal :unit_cost,          precision: 20, scale: 2, null: false
      t.string  :status,             null: false, default: "active"
      t.timestamps
    end

    add_index :product_lots, :product_id
    add_index :product_lots, :purchase_order_id
    add_index :product_lots, :status
    add_index :product_lots, :received_date
    add_index :product_lots, :lot_number, unique: true
    add_foreign_key :product_lots, :products
    add_foreign_key :product_lots, :purchase_orders
  end
end
