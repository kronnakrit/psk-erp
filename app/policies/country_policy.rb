# frozen_string_literal: true

class CountryPolicy < ApplicationPolicy
  # Public read — no authentication required
  def index? = true
  def show?  = true

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
