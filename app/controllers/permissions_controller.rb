class PermissionsController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_policy_scoped

  def index
    @permissions = Permissions::ALL
    authorize :permission, :index?
  end
end
