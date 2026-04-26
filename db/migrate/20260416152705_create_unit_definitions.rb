class CreateUnitDefinitions < ActiveRecord::Migration[8.1]
  def change
    create_table :unit_definitions do |t|
      t.references :unit_group, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :ratio, null: false
      t.boolean :is_migration_placeholder, null: false, default: false

      t.timestamps
    end

    add_check_constraint :unit_definitions, "ratio > 0", name: "chk_unit_definitions_ratio_positive"
    add_index :unit_definitions, [:unit_group_id, :ratio], unique: true, where: "ratio = 1 AND is_migration_placeholder = false", name: "idx_unit_defs_on_group_and_ratio_1"
    add_index :unit_definitions, [:unit_group_id, :name], unique: true
  end
end
