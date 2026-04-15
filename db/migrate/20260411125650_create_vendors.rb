class CreateVendors < ActiveRecord::Migration[8.1]
  def change
    create_table :vendors do |t|
      t.string :name, null: false
      t.string :initial_name
      t.text :description
      t.text :address
      t.text :remark
      t.string :telephone

      t.timestamps
    end

    add_index :vendors, :name, unique: true
    add_index :vendors, :initial_name, unique: true
  end
end
