class CreateProductCategoryProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :product_category_products, id: false do |t|
      t.bigint :product_id,          null: false
      t.bigint :product_category_id, null: false
    end

    add_index :product_category_products, %i[product_id product_category_id], unique: true,
              name: "idx_product_category_products_unique"
    add_foreign_key :product_category_products, :products,           column: :product_id,          on_delete: :cascade
    add_foreign_key :product_category_products, :product_categories, column: :product_category_id, on_delete: :cascade
  end
end
