# frozen_string_literal: true

module PermissionCheckable
  extend ActiveSupport::Concern

  # Returns true when the current user's role includes the given permission codename.
  # Safe to call even when the user has no profile or role yet.
  def permission?(codename)
    role = current_user&.profile&.role
    role&.permissions&.include?(codename) || false
  end
end
