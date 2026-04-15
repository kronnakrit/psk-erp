class CreateOrderLines < ActiveRecord::Migration[8.1]
  def change
    create_table :order_lines do |t|
      t.references :order,   null: false, foreign_key: { on_delete: :cascade }
      t.references :product, null: false, foreign_key: { on_delete: :restrict }
      t.string  :unit,          limit: 2, default: "Dz"
      t.decimal :quantity,      precision: 8,  scale: 2, null: false
      t.decimal :unit_price,    precision: 20, scale: 2, null: false
      t.decimal :discount_price, precision: 20, scale: 2, default: 0, null: false
      t.decimal :total_price,   precision: 20, scale: 2, null: false
      t.text    :description
      t.text    :remark
      t.integer :idx, default: 0

      t.timestamps
    end
  end
end
