# frozen_string_literal: true

class PurchaseOrderPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      permission?("view_purchase_orders") ? scope.all : scope.none
    end
  end

  def index?   = permission?("view_purchase_orders")
  def show?    = permission?("view_purchase_orders")
  def new?     = permission?("add_purchase_orders")
  def create?  = permission?("add_purchase_orders")
  def edit?    = permission?("change_purchase_orders")
  def update?  = permission?("change_purchase_orders")
  def destroy? = permission?("delete_purchase_orders")
  def confirm? = permission?("change_purchase_orders")
end
