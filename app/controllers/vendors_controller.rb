class VendorsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vendor, only: %i[show edit update destroy]

  def index
    @ransack = policy_scope(Vendor).ransack(params[:q])
    @ransack.sorts = "name asc" if @ransack.sorts.empty?
    @pagy, @vendors = pagy(@ransack.result)
    authorize Vendor
  end

  def show
    authorize @vendor
  end

  def new
    @vendor = Vendor.new
    authorize @vendor
  end

  def edit
    authorize @vendor
  end

  def create
    @vendor = Vendor.new(vendor_params)
    authorize @vendor
    if @vendor.save
      redirect_to vendors_path, notice: "Vendor created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @vendor
    if @vendor.update(vendor_params)
      redirect_to vendors_path, notice: "Vendor updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @vendor
    @vendor.destroy
    redirect_to vendors_path, notice: "Vendor deleted successfully."
  end

  def initialize_names
    authorize Vendor, :initialize_names?
    vendors = Vendor.where(initial_name: nil)
    vendors.each(&:auto_set_initial_name)
    redirect_to vendors_path, notice: "Initialized #{vendors.size} vendor name(s)."
  end

  private

  def set_vendor
    @vendor = Vendor.find(params[:id])
  end

  def vendor_params
    params.expect(vendor: %i[name initial_name description address remark telephone])
  end
end
