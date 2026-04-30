class RemoveUnitFromProducts < ActiveRecord::Migration[8.1]
  def change
    remove_column :products, :unit, :string
  end
end
