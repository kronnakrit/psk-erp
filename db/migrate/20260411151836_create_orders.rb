class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string  :order_number, null: false
      t.references :customer,         null: false, foreign_key: { on_delete: :cascade }
      t.references :logistic_company, null: true,  foreign_key: { on_delete: :nullify }
      t.string  :telephone,           limit: 20
      t.text    :address
      t.boolean :has_vat,              default: false, null: false
      t.boolean :is_included_vat,      default: false, null: false
      t.decimal :total_price,          precision: 20, scale: 2, default: 0, null: false
      t.decimal :discount_price,       precision: 20, scale: 2, default: 0, null: false
      t.boolean :is_discount_percentage, default: false, null: false
      t.decimal :discount_percentage,  precision: 20, scale: 2, default: 0, null: false
      t.decimal :vat_price,            precision: 20, scale: 2, default: 0, null: false
      t.decimal :grand_total,          precision: 20, scale: 2, default: 0, null: false
      t.text    :remark
      t.text    :internal_note
      t.string  :status,              limit: 2, null: false, default: "Dr"
      t.date    :running_date,        null: false
      t.boolean :is_withholding_tax,  default: true, null: false
      t.decimal :withholding_tax,     precision: 20, scale: 2, default: 0, null: false
      t.string  :logistic_status,     limit: 3, default: "WTS"
      t.bigint  :created_by_id
      t.bigint  :updated_by_id

      t.timestamps
    end

    add_index :orders, :order_number, unique: true
    add_index :orders, :running_date
    add_index :orders, :status
    add_index :orders, :logistic_status
    add_index :orders, :created_by_id
    add_index :orders, :updated_by_id
    add_foreign_key :orders, :users, column: :created_by_id, on_delete: :nullify
    add_foreign_key :orders, :users, column: :updated_by_id, on_delete: :nullify
  end
end
