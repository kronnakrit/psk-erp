# frozen_string_literal: true

class StockLocation < ApplicationRecord
  has_many :product_stock_locations, dependent: :destroy
  has_many :product_stocks, through: :product_stock_locations

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def self.ransackable_attributes(_auth_object = nil)
    %w[name description]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
