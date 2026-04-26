# frozen_string_literal: true

class CreateProductStockLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :product_stock_locations do |t|
      t.references :product_stock,  null: false, foreign_key: true
      t.references :stock_location, null: false, foreign_key: true

      t.timestamps
    end

    add_index :product_stock_locations, %i[product_stock_id stock_location_id],
              unique: true,
              name: "index_product_stock_locations_unique_pair"
  end
end
