class LogisticCompaniesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_logistic_company, only: %i[show edit update destroy]

  def index
    @ransack = policy_scope(LogisticCompany).ransack(params[:q])
    @ransack.sorts = "name asc" if @ransack.sorts.empty?
    @pagy, @logistic_companies = pagy(@ransack.result)
    authorize LogisticCompany
  end

  def show
    authorize @logistic_company
  end

  def new
    @logistic_company = LogisticCompany.new
    authorize @logistic_company
  end

  def edit
    authorize @logistic_company
  end

  def create
    @logistic_company = LogisticCompany.new(logistic_company_params)
    authorize @logistic_company
    if @logistic_company.save
      redirect_to logistic_companies_path, notice: "Logistic company created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @logistic_company
    if @logistic_company.update(logistic_company_params)
      redirect_to logistic_companies_path, notice: "Logistic company updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @logistic_company
    @logistic_company.destroy!
    redirect_to logistic_companies_path, notice: "Logistic company deleted."
  end

  private

  def set_logistic_company
    @logistic_company = LogisticCompany.find(params[:id])
  end

  def logistic_company_params
    params.expect(logistic_company: %i[name address remark telephone])
  end
end
