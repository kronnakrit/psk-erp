class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.string :permissions, array: true, default: []
      t.bigint :group_id

      t.timestamps
    end

    add_index :roles, :name, unique: true
  end
end
