class Profile < ApplicationRecord
  belongs_to :user
  belongs_to :role, optional: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[id first_name last_name telephone address user_id role_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user role]
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end
end
