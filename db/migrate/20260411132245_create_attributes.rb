class CreateAttributes < ActiveRecord::Migration[8.1]
  def change
    create_table :attributes do |t|
      t.string :name, null: false
      t.references :product_class, null: false, foreign_key: true

      t.timestamps
    end

    add_index :attributes, %i[name product_class_id], unique: true
  end
end
