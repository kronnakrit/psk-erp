class CountriesController < ApplicationController
  before_action :authenticate_user!, only: %i[new create edit update destroy]
  before_action :set_country, only: %i[show edit update destroy]

  def index
    @ransack = policy_scope(Country).ransack(params[:q])
    @ransack.sorts = "printable_name asc" if @ransack.sorts.empty?
    @pagy, @countries = pagy(@ransack.result)
    authorize Country
  end

  def show
    authorize @country
  end

  def new
    @country = Country.new
    authorize @country
  end

  def edit
    authorize @country
  end

  def create
    @country = Country.new(country_params)
    authorize @country
    if @country.save
      redirect_to countries_path, notice: "Country created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @country
    if @country.update(country_params)
      redirect_to countries_path, notice: "Country updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @country
    @country.destroy!
    redirect_to countries_path, notice: "Country deleted."
  end

  private

  def set_country
    @country = Country.find(params[:id])
  end

  def country_params
    params.expect(country: %i[iso_3166_1_a2 iso_3166_1_a3 iso_3166_1_numeric printable_name name])
  end
end
