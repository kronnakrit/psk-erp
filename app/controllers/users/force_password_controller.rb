module Users
  class ForcePasswordController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user

    def update
      authorize @user, :update?

      if params[:password1] != params[:password2]
        redirect_to edit_user_path(@user), alert: "Passwords do not match."
        return
      end

      if @user.update(password: params[:password1])
        redirect_to users_path, notice: "Password updated successfully."
      else
        redirect_to edit_user_path(@user), alert: @user.errors.full_messages.to_sentence
      end
    end

    private

    def set_user
      @user = User.find(params[:user_id])
    end
  end
end
