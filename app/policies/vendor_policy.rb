# frozen_string_literal: true

class VendorPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def initialize_names?
    permission?("change_vendors")
  end
end
