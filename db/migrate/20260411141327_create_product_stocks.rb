class CreateProductStocks < ActiveRecord::Migration[8.1]
  def change
    create_table :product_stocks do |t|
      t.references :branch,  null: false, foreign_key: { on_delete: :restrict }
      t.references :product, null: false, foreign_key: { on_delete: :restrict }
      t.decimal :amount,         precision: 12, scale: 2, default: 0, null: false
      t.decimal :holding_amount, precision: 12, scale: 2, default: 0, null: false

      t.timestamps
    end

    add_index :product_stocks, %i[branch_id product_id], unique: true
  end
end
