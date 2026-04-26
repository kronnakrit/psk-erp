class CreatePurchaseOrderLines < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_order_lines do |t|
      t.references :purchase_order,  null: false, foreign_key: true
      t.references :product,         null: false, foreign_key: true
      t.references :unit_definition, null: false, foreign_key: true
      t.decimal    :quantity,  precision: 8,  scale: 2, null: false
      t.decimal    :unit_cost, precision: 20, scale: 2, null: false, default: 0

      t.timestamps
    end
  end
end
