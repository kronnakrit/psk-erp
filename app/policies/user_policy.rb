# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def activate?   = permission?("change_users")
  def deactivate? = permission?("change_users")

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
