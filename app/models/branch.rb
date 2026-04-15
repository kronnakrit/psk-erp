# frozen_string_literal: true

class Branch < ApplicationRecord
  has_many :product_stocks, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def self.default
    find_by(name: "Main Branch") || first
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name created_at]
  end

  def self.ransackable_associations(_auth_object = nil) = []
end
