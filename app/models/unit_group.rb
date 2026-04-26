# frozen_string_literal: true

class UnitGroup < ApplicationRecord
  has_many :unit_definitions, dependent: :destroy
  has_one :main_unit_definition, -> { where(is_main: true) }, class_name: "UnitDefinition", dependent: nil
  has_many :products

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validate :validate_base_unit_if_default, if: -> { is_default? }

  before_save :enforce_single_default, if: -> { is_default_changed?(from: false, to: true) }
  before_destroy :prevent_if_assigned_to_products

  private

  def validate_base_unit_if_default
    return if unit_definitions.any? { |ud| ud.ratio == 1 && !ud.marked_for_destruction? }

    errors.add(:base, "Cannot set as default: group has no base unit (ratio = 1).")
  end

  def enforce_single_default
    UnitGroup.where.not(id: id).update_all(is_default: false) # rubocop:disable Rails/SkipsModelValidations
  end

  def prevent_if_assigned_to_products
    return unless products.exists?

    errors.add(:base, "Cannot delete a unit group that is assigned to products")
    throw(:abort)
  end
end
