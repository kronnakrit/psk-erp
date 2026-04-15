class CreateOrderImages < ActiveRecord::Migration[8.1]
  def change
    create_table :order_images do |t|
      t.references :order, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, default: 0, null: false

      t.timestamps
    end
  end
end
