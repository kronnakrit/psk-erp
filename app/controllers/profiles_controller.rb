class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @profile = current_user.profile
    authorize @profile
  end

  def update
    @profile = current_user.profile
    authorize @profile
    if @profile.update(profile_params)
      redirect_to profile_path, notice: "Profile updated successfully."
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def profile_params
    params.expect(profile: %i[first_name last_name address remark telephone])
  end
end
