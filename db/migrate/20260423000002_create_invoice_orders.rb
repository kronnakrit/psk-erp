# frozen_string_literal: true

class CreateInvoiceOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_orders do |t|
      t.references :invoice, null: false, foreign_key: { on_delete: :cascade }
      t.references :order,   null: false, foreign_key: { on_delete: :restrict }
      t.timestamps
    end

    add_index :invoice_orders, %i[invoice_id order_id], unique: true
  end
end
