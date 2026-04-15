# frozen_string_literal: true

class ProductClass < ApplicationRecord
  has_many :product_class_attributes, class_name: "Attribute", dependent: :destroy
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def self.ransackable_attributes(_auth_object = nil)
    %w[name]
  end

  def self.ransackable_associations(_auth_object = nil) = []
end
