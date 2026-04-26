class LocalesController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def update
    locale = params[:locale].to_s
    unless I18n.available_locales.map(&:to_s).include?(locale)
      return render plain: "Unsupported locale", status: :unprocessable_entity
    end

    if current_user.profile.update(preferred_locale: locale)
      redirect_back_or_to root_path
    else
      render plain: "Invalid locale", status: :unprocessable_entity
    end
  end
end
