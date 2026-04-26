# frozen_string_literal: true

class CreateInvoiceImages < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_images do |t|
      t.references :invoice, null: false, foreign_key: { on_delete: :cascade }
      t.integer    :position, null: false, default: 0
      t.timestamps
    end
  end
end
