# frozen_string_literal: true

class ProductPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(product_type: %w[Sa Pr])
    end
  end

  def can_view_cost?
    permission?("can_view_cost")
  end

  def duplicate?
    permission?("add_products")
  end
end
