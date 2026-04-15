# frozen_string_literal: true

class ProfilePolicy < ApplicationPolicy
  # Users can always view and update their own profile.
  def show?
    user == record.user
  end

  def update?
    user == record.user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end
end
