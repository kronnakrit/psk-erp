class RolesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_role, only: %i[show edit update destroy]

  def index
    @ransack = policy_scope(Role).ransack(params[:q])
    @ransack.sorts = "name asc" if @ransack.sorts.empty?
    @pagy, @roles = pagy(@ransack.result)
    authorize Role
  end

  def show
    authorize @role
  end

  def new
    @role = Role.new
    @permissions = Permissions::ALL
    authorize @role
  end

  def edit
    @permissions = Permissions::ALL
    authorize @role
  end

  def create
    @role = Role.new(role_params)
    authorize @role
    @permissions = Permissions::ALL
    if @role.save
      redirect_to roles_path, notice: "Role created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @role
    @permissions = Permissions::ALL
    if @role.update(role_params)
      redirect_to roles_path, notice: "Role updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @role
    @role.destroy!
    redirect_to roles_path, notice: "Role deleted."
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def role_params
    params.expect(role: [:name, :group_id, { permissions: [] }])
  end
end
