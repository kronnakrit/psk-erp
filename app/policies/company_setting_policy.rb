# frozen_string_literal: true

class CompanySettingPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def show?
    user.present?
  end

  def edit?
    permission?("change_company_settings")
  end

  def update?
    edit?
  end
end
