# frozen_string_literal: true

class SupplierPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      permission?("view_suppliers") ? scope.all : scope.none
    end
  end

  def index?   = permission?("view_suppliers")
  def show?    = permission?("view_suppliers")
  def new?     = permission?("add_suppliers")
  def create?  = permission?("add_suppliers")
  def edit?    = permission?("change_suppliers")
  def update?  = permission?("change_suppliers")
  def destroy? = permission?("delete_suppliers")
end
