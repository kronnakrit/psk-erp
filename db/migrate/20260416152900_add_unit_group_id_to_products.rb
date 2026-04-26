class AddUnitGroupIdToProducts < ActiveRecord::Migration[8.1]
  def change
    add_reference :products, :unit_group, null: true, foreign_key: { on_delete: :restrict }
  end
end
