class CreateProductClasses < ActiveRecord::Migration[8.1]
  def change
    create_table :product_classes do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :product_classes, :name, unique: true
  end
end
