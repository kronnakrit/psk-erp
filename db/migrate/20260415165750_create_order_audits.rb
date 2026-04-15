class CreateOrderAudits < ActiveRecord::Migration[8.1]
  def change
    create_table :order_audits do |t|
      t.references :order,         null: false, foreign_key: { on_delete: :cascade }
      t.bigint     :changed_by_id, null: true
      t.string     :event_type,    limit: 20,  null: false
      t.string     :field_name,    limit: 100, null: true
      t.text       :previous_value,             null: true
      t.text       :new_value,                  null: true
      t.datetime   :changed_at,                 null: false, default: -> { "NOW()" }
    end

    add_foreign_key :order_audits, :users, column: :changed_by_id, on_delete: :nullify
    add_index :order_audits, %i[order_id changed_at]
  end
end
