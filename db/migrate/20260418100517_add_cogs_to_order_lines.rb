class AddCogsToOrderLines < ActiveRecord::Migration[8.1]
  def change
    add_column :order_lines, :cogs, :decimal, precision: 20, scale: 2, null: false, default: 0
  end
end
