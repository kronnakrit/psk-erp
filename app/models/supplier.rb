# frozen_string_literal: true

class Supplier < ApplicationRecord
  has_many :purchase_orders, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[name telephone address remark is_active]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
