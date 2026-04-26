# frozen_string_literal: true

class ProductStockLocation < ApplicationRecord
  belongs_to :product_stock
  belongs_to :stock_location

  validates :product_stock_id, uniqueness: { scope: :stock_location_id }
end
