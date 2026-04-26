class AddUnitDefinitionIdToOrderLines < ActiveRecord::Migration[8.1]
  def change
    add_column :order_lines, :unit_definition_id, :bigint
    add_index  :order_lines, :unit_definition_id
    add_foreign_key :order_lines, :unit_definitions, on_delete: :restrict
  end
end
