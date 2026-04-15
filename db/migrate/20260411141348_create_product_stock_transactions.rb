class CreateProductStockTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :product_stock_transactions do |t|
      t.references :product_stock, null: false, foreign_key: { on_delete: :restrict }
      t.string  :transaction_type,  limit: 2,  null: false
      t.decimal :amount,            precision: 12, scale: 2, null: false
      t.string  :related_object_type
      t.bigint  :related_object_id
      t.string  :reason,            limit: 255
      t.decimal :recal_checkpoint,  precision: 12, scale: 2, default: 0, null: false

      t.timestamps
    end

    add_index :product_stock_transactions, %i[related_object_type related_object_id]
    add_index :product_stock_transactions, :transaction_type
  end
end
