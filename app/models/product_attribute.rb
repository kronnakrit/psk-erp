# frozen_string_literal: true

class ProductAttribute < ApplicationRecord
  belongs_to :product
  belongs_to :product_attr, class_name: "Attribute", foreign_key: :attribute_id, inverse_of: :product_attributes

  validates :attribute_id, uniqueness: { scope: :product_id }
end
