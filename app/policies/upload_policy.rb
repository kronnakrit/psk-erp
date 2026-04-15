# frozen_string_literal: true

class UploadPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end

  def index?  = permission?("view_uploads")
  def create? = permission?("add_uploads")
end
