# frozen_string_literal: true

class CreateInvoiceAudits < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_audits do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references :invoice,    null: false, foreign_key: { on_delete: :cascade }
      t.references :changed_by, foreign_key: { to_table: :users, on_delete: :nullify }, null: true
      t.string     :event_type, null: false, limit: 20
      t.string     :field_name, limit: 100
      t.text       :previous_value
      t.text       :new_value
      t.datetime   :changed_at, null: false, default: -> { "NOW()" }
    end

    add_index :invoice_audits, %i[invoice_id changed_at]
  end
end
