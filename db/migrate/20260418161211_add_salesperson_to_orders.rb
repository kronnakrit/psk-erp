class AddSalespersonToOrders < ActiveRecord::Migration[8.1]
  def change
    add_reference :orders, :salesperson, foreign_key: { to_table: :users }, null: true
  end
end
