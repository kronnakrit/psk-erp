class CreateProductImages < ActiveRecord::Migration[8.1]
  def change
    create_table :product_images do |t|
      t.references :product, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, default: 0, null: false

      t.timestamps
    end
  end
end
