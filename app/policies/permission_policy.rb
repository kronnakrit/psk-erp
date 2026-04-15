# frozen_string_literal: true

class PermissionPolicy < ApplicationPolicy
  def index?
    permission?("view_roles") || permission?("change_roles") || permission?("add_roles")
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
    end
  end
end
