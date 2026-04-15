class Customer < ApplicationRecord
  include SoftDeletable

  belongs_to :country, optional: true, primary_key: :iso_3166_1_a2
  belongs_to :logistic_company, optional: true

  validates :first_name, presence: true

  def fullname
    last_name.blank? ? first_name : "#{first_name} #{last_name}"
  end

  # Alias kept for backward compatibility
  alias get_fullname fullname

  def self.ransackable_attributes(_auth_object = nil)
    %w[first_name last_name address remark telephone]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[logistic_company]
  end
end
