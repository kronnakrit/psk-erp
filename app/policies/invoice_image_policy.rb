# frozen_string_literal: true

class InvoiceImagePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def create?
    permission?("change_invoices")
  end

  def destroy?
    permission?("change_invoices")
  end
end
