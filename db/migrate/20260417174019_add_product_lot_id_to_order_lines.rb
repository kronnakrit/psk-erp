class AddProductLotIdToOrderLines < ActiveRecord::Migration[8.1]
  def change
    add_column :order_lines, :product_lot_id, :bigint
    add_index  :order_lines, :product_lot_id
    add_foreign_key :order_lines, :product_lots
  end
end
