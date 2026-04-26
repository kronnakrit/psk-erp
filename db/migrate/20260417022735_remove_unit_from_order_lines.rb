class RemoveUnitFromOrderLines < ActiveRecord::Migration[8.1]
  def change
    remove_column :order_lines, :unit, :string
  end
end
