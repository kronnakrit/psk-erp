class CustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_customer, only: %i[show edit update destroy]

  def index
    @ransack = policy_scope(Customer).includes(:logistic_company, :country).ransack(params[:q])
    @ransack.sorts = "first_name asc" if @ransack.sorts.empty?
    @pagy, @customers = pagy(@ransack.result)
    authorize Customer
  end

  def show
    authorize @customer
  end

  def new
    @customer = Customer.new
    authorize @customer
    load_form_data
  end

  def edit
    authorize @customer
    load_form_data
  end

  def create
    @customer = Customer.new(customer_params)
    authorize @customer
    if @customer.save
      redirect_to customers_path, notice: "Customer created successfully."
    else
      load_form_data
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @customer
    if @customer.update(customer_params)
      redirect_to customers_path, notice: "Customer updated successfully."
    else
      load_form_data
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @customer
    @customer.soft_delete!
    redirect_to customers_path, notice: "Customer deleted."
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def load_form_data
    @countries = Country.order(:printable_name)
    @logistic_companies = LogisticCompany.order(:name)
  end

  def customer_params
    params.expect(customer: %i[first_name last_name address remark telephone country_id logistic_company_id])
  end
end
