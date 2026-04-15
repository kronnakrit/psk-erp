class CreateProductAttributes < ActiveRecord::Migration[8.1]
  def change
    create_table :product_attributes do |t|
      t.bigint :product_id, null: false
      t.references :attribute, null: false, foreign_key: true
      t.string :value

      t.timestamps
    end

    add_index :product_attributes, :product_id
    add_index :product_attributes, %i[product_id attribute_id], unique: true
  end
end
