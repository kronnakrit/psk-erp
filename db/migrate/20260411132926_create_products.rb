class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string  :sku,            null: false
      t.string  :product_type,   null: false, limit: 2   # Sa, Pr, Ch
      t.string  :barcode
      t.string  :name,           null: false
      t.text    :description
      t.text    :description_th
      t.string  :unit
      t.decimal :price,          precision: 20, scale: 2
      t.decimal :cost,           precision: 20, scale: 2
      t.text    :remark
      t.boolean :enable_stock,   default: false, null: false
      t.datetime :deleted_at

      t.references :vendor,        foreign_key: true, null: true
      t.references :brand,         foreign_key: true, null: true
      t.references :product_class, foreign_key: true, null: true
      t.bigint :parent_id                          # self-referential; FK added below

      t.timestamps
    end

    add_index :products, :sku, unique: true
    add_index :products, :barcode
    add_index :products, :product_type
    add_index :products, :deleted_at
    add_index :products, :parent_id
    add_foreign_key :products, :products, column: :parent_id
    add_foreign_key :product_attributes, :products, column: :product_id, on_delete: :cascade
  end
end
