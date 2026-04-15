# frozen_string_literal: true

class BranchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_branch, only: %i[show edit update destroy]

  def index
    @ransack = policy_scope(Branch).ransack(params[:q])
    @ransack.sorts = "name asc" if @ransack.sorts.empty?
    @pagy, @branches = pagy(@ransack.result)
    authorize Branch
  end

  def show
    authorize @branch
  end

  def new
    @branch = Branch.new
    authorize @branch
  end

  def edit
    authorize @branch
  end

  def create
    @branch = Branch.new(branch_params)
    authorize @branch
    if @branch.save
      redirect_to branches_path, notice: "Branch created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @branch
    if @branch.update(branch_params)
      redirect_to branches_path, notice: "Branch updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @branch
    @branch.destroy
    redirect_to branches_path, notice: "Branch deleted successfully."
  end

  private

  def set_branch
    @branch = Branch.find(params[:id])
  end

  def branch_params
    params.expect(branch: [:name])
  end
end
