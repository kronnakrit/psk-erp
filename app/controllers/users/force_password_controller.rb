module Users
  class ForcePasswordController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user

    def update
      authorize @user, :update?

      passwords = force_password_params

      if passwords[:password1] != passwords[:password2]
        redirect_to edit_user_path(@user), alert: "Passwords do not match."
        return
      end

      if @user.update(password: passwords[:password1])
        redirect_to users_path, notice: "Password updated successfully."
      else
        redirect_to edit_user_path(@user), alert: @user.errors.full_messages.to_sentence
      end
    end

    private

    def set_user
      @user = User.find(params[:user_id])
    end

    def force_password_params
      params.permit(:password1, :password2)
    end
  end
end
