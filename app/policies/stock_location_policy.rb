# frozen_string_literal: true

class StockLocationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def index?   = permission?("view_product_stocks")
  def show?    = permission?("view_product_stocks")
  def new?     = permission?("change_product_stocks")
  def create?  = permission?("change_product_stocks")
  def edit?    = permission?("change_product_stocks")
  def update?  = permission?("change_product_stocks")
  def destroy? = permission?("change_product_stocks")
end
