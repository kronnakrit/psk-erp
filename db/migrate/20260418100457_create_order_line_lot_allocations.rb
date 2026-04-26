class CreateOrderLineLotAllocations < ActiveRecord::Migration[8.1]
  def change
    create_table :order_line_lot_allocations do |t|
      t.bigint  :order_line_id,   null: false
      t.bigint  :product_lot_id   # nullable — nil for phantom (negative-stock) allocations
      t.decimal :allocated_quantity, precision: 8,  scale: 2, null: false
      t.decimal :unit_cost,          precision: 20, scale: 2, null: false, default: "0"
      t.timestamps
    end

    add_index :order_line_lot_allocations, :order_line_id
    add_index :order_line_lot_allocations, :product_lot_id
    add_foreign_key :order_line_lot_allocations, :order_lines
    add_foreign_key :order_line_lot_allocations, :product_lots, column: :product_lot_id
  end
end
