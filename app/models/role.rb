class Role < ApplicationRecord
  has_many :profiles, dependent: :nullify

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name group_id created_at updated_at]
  end

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
