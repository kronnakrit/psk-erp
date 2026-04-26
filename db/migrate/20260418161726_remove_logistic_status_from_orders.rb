class RemoveLogisticStatusFromOrders < ActiveRecord::Migration[8.1]
  def change
    remove_column :orders, :logistic_status, :string
  end
end
