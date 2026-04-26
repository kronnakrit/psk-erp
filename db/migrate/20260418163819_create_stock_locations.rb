# frozen_string_literal: true

class CreateStockLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_locations do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_index :stock_locations, "lower(name)", unique: true, name: "index_stock_locations_on_lower_name"
  end
end
