class CreateSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.string  :name,      null: false
      t.string  :telephone
      t.text    :address
      t.text    :remark
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :suppliers, :name, unique: true
  end
end
