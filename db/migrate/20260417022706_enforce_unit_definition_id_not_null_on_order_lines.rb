class EnforceUnitDefinitionIdNotNullOnOrderLines < ActiveRecord::Migration[8.1]
  def change
    change_column_null :order_lines, :unit_definition_id, false
  end
end
