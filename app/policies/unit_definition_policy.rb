# frozen_string_literal: true

class UnitDefinitionPolicy < ApplicationPolicy
  def create?   = permission?("manage_unit_groups")
  def set_main? = permission?("manage_unit_groups")
  def destroy?  = permission?("manage_unit_groups")
end
