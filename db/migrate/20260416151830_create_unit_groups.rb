class CreateUnitGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :unit_groups do |t|
      t.string :name, null: false
      t.boolean :is_default, null: false, default: false

      t.timestamps
    end
    
    add_index :unit_groups, :name, unique: true
  end
end
