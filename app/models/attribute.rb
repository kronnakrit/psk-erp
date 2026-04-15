# frozen_string_literal: true

class Attribute < ApplicationRecord
  belongs_to :product_class
  has_many :product_attributes, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :product_class_id, case_sensitive: false }

  def self.ransackable_attributes(_auth_object = nil)
    %w[name product_class_id]
  end

  def self.ransackable_associations(_auth_object = nil) = []
end
