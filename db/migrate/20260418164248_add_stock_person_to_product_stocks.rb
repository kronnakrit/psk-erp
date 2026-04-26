# frozen_string_literal: true

class AddStockPersonToProductStocks < ActiveRecord::Migration[8.0]
  def change
    add_reference :product_stocks, :stock_person,
                  null: true, foreign_key: { to_table: :users }, index: true
  end
end
