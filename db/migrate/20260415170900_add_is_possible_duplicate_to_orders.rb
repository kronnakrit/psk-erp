class AddIsPossibleDuplicateToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :is_possible_duplicate, :boolean, default: false, null: false
    add_index :orders, :is_possible_duplicate, name: "idx_orders_is_possible_duplicate"
  end
end
