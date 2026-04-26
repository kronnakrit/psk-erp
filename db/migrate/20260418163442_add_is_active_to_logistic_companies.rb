# frozen_string_literal: true

class AddIsActiveToLogisticCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :logistic_companies, :is_active, :boolean, default: true, null: false
  end
end
