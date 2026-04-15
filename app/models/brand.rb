# frozen_string_literal: true

class Brand < ApplicationRecord
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def self.ransackable_attributes(_auth_object = nil)
    %w[name description remark]
  end

  def self.ransackable_associations(_auth_object = nil) = []
end
