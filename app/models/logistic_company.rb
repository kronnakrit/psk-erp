class LogisticCompany < ApplicationRecord
  validates :name, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[name address remark telephone]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
