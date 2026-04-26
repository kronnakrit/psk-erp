# frozen_string_literal: true

class UnitGroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_unit_group, only: %i[show edit update destroy set_default]
  after_action :verify_authorized

  def index
    authorize UnitGroup
    @unit_groups = policy_scope(UnitGroup).includes(:unit_definitions).order(name: :asc)
  end

  def show
    @unit_definition = UnitDefinition.new
  end

  def new
    authorize UnitGroup
    @unit_group = UnitGroup.new
  end

  def edit; end

  def create
    authorize UnitGroup
    @unit_group = UnitGroup.new(unit_group_params)

    if @unit_group.save
      redirect_to unit_group_path(@unit_group), notice: "Unit group created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @unit_group.update(unit_group_params)
      redirect_to unit_group_path(@unit_group), notice: "Unit group updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @unit_group.destroy
      redirect_to unit_groups_path, notice: "Unit group deleted."
    else
      redirect_to unit_groups_path, alert: "Cannot delete: this unit group is assigned to products.", status: :conflict
    end
  end

  def set_default
    @unit_group.is_default = true
    if @unit_group.save
      redirect_back_or_to(unit_groups_path, notice: "Default unit group updated.")
    else
      redirect_back_or_to(
        unit_groups_path,
        alert: "Cannot set as default: group has no base unit (ratio = 1).",
        status: :unprocessable_content
      )
    end
  end

  private

  def set_unit_group
    @unit_group = UnitGroup.find(params[:id])
    authorize @unit_group
  end

  def unit_group_params
    params.expect(unit_group: %i[name is_default])
  end
end
