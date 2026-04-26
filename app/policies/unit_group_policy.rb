# frozen_string_literal: true

class UnitGroupPolicy < ApplicationPolicy
  def index?       = permission?("manage_unit_groups")
  def show?        = permission?("manage_unit_groups")
  def new?         = permission?("manage_unit_groups")
  def create?      = permission?("manage_unit_groups")
  def edit?        = permission?("manage_unit_groups")
  def update?      = permission?("manage_unit_groups")
  def destroy?     = permission?("manage_unit_groups")
  def set_default? = permission?("manage_unit_groups")

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
