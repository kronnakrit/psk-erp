class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include PermissionCheckable
  include Pagy::Method

  layout :layout_by_resource

  helper_method :permission?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  after_action :verify_authorized,    if: -> { !devise_controller? && action_name != "index" }
  after_action :verify_policy_scoped, if: -> { !devise_controller? && action_name == "index" }

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::InvalidForeignKey, with: :record_referenced_by_other

  before_action :set_current_user

  private

  def set_current_user
    Current.user = current_user
  end

  def layout_by_resource
    devise_controller? ? "devise" : "application"
  end

  def user_not_authorized
    respond_to do |format|
      format.json { render json: { error: "Forbidden" }, status: :forbidden }
      format.html do
        redirect_back_or_to root_path, alert: "You are not authorized."
      end
    end
  end

  def record_referenced_by_other
    respond_to do |format|
      format.json { render json: { error: "Cannot delete: record is referenced by other data." }, status: :conflict }
      format.html do
        redirect_back_or_to root_path, alert: "Cannot delete: record is still referenced by other data."
      end
    end
  end
end
