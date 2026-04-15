# frozen_string_literal: true

class ProductCategory < ApplicationRecord
  has_and_belongs_to_many :products, join_table: :product_category_products # rubocop:disable Rails/HasAndBelongsToMany

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def self.ransackable_attributes(_auth_object = nil)
    %w[name]
  end

  def self.ransackable_associations(_auth_object = nil) = []
end
