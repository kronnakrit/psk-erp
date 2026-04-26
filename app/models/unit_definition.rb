# frozen_string_literal: true

class UnitDefinition < ApplicationRecord
  belongs_to :unit_group

  validates :name, :ratio, presence: true
  validates :ratio, numericality: { only_integer: true, greater_than: 0 }

  validates :ratio,
            uniqueness: {
              scope: :unit_group_id,
              message: "1 already exists in this unit group"
            },
            if: -> { ratio == 1 && !is_migration_placeholder? }

  validates :name,
            uniqueness: {
              scope: :unit_group_id,
              case_sensitive: false
            }

  before_destroy :prevent_deleting_last_base_unit_if_default

  private

  def prevent_deleting_last_base_unit_if_default
    return unless ratio == 1 && unit_group.is_default?
    return if unit_group.unit_definitions.where(ratio: 1).where.not(id: id).exists?

    errors.add(:base, "Cannot remove the base unit from the default group.")
    throw(:abort)
  end
end
