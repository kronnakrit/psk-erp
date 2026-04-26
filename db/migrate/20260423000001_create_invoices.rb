# frozen_string_literal: true

class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.string     :invoice_number, null: false, limit: 20
      t.references :customer,       null: false, foreign_key: true
      t.string     :status,         null: false, limit: 2, default: "Dr"
      t.date       :invoice_date,   null: false
      t.text       :remark
      t.decimal    :total_amount,   null: false, precision: 20, scale: 2, default: "0.0"
      t.references :created_by,     foreign_key: { to_table: :users }, null: true
      t.references :updated_by,     foreign_key: { to_table: :users }, null: true
      t.timestamps
    end

    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, :status
    add_index :invoices, :invoice_date
  end
end
