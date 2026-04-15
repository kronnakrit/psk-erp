class AddAdjusterToProductStockTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :product_stock_transactions, :adjuster_id, :bigint, null: true
    add_foreign_key :product_stock_transactions, :users, column: :adjuster_id, on_delete: :nullify
    add_index :product_stock_transactions, :adjuster_id
  end
end
