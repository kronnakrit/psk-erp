class CreatePurchaseOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_orders do |t|
      t.references :supplier, null: false, foreign_key: true
      t.string :po_number, null: false
      t.date   :po_date,   null: false
      t.string :status,    null: false, default: "Dr", limit: 2
      t.text   :remark

      t.timestamps
    end

    add_index :purchase_orders, :po_number, unique: true
    add_index :purchase_orders, :status
    add_index :purchase_orders, :po_date
  end
end
