class AddIsMainToUnitDefinitions < ActiveRecord::Migration[8.1]
  def change
    add_column :unit_definitions, :is_main, :boolean, default: false, null: false
    add_index :unit_definitions, :unit_group_id,
              name: "idx_unit_defs_one_main_per_group",
              unique: true,
              where: "(is_main = true)"
  end
end
