# frozen_string_literal: true

class OrderLinePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def create?
    permission?("change_orders") && record.order.status == "Dr"
  end

  def update?
    permission?("change_orders") && record.order.status == "Dr"
  end

  def destroy?
    permission?("change_orders") && record.order.status == "Dr"
  end
end
