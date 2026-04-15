# frozen_string_literal: true

class Vendor < ApplicationRecord
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :initial_name, uniqueness: { case_sensitive: false, allow_blank: true }

  after_create :auto_set_initial_name

  def self.ransackable_attributes(_auth_object = nil)
    %w[name initial_name description address remark telephone]
  end

  def self.ransackable_associations(_auth_object = nil) = []

  def auto_set_initial_name
    return if initial_name.present?

    update_column(:initial_name, "#{name}-#{id}") # rubocop:disable Rails/SkipsModelValidations
  end
end
