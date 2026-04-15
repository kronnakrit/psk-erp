class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: %i[edit update destroy activate deactivate]

  def index
    @ransack = policy_scope(User).includes(:profile).ransack(params[:q])
    @ransack.sorts = "created_at desc" if @ransack.sorts.empty?
    @pagy, @users = pagy(@ransack.result)
    authorize User
  end

  def new
    @user = User.new
    @user.build_profile
    authorize @user
  end

  def edit
    authorize @user
    @user.build_profile if @user.profile.nil?
  end

  def create
    @user = User.new(user_params)
    authorize @user
    if @user.save
      redirect_to users_path, notice: "User created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @user
    if @user.update(user_params)
      redirect_to users_path, notice: "User updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @user
    @user.destroy!
    redirect_to users_path, notice: "User deleted."
  end

  def activate
    authorize @user
    @user.update!(is_active: true)
    redirect_to users_path, notice: "User activated."
  end

  def deactivate
    authorize @user
    @user.update!(is_active: false)
    redirect_to users_path, notice: "User deactivated."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.expect(
      user: [:email, :username, :password, :password_confirmation, :is_active,
             { profile_attributes: %i[id first_name last_name address remark telephone role_id] }]
    )
  end
end
