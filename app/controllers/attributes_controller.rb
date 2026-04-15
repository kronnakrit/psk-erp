class AttributesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product_class
  before_action :set_attribute, only: %i[show edit update destroy]

  def index
    @attributes = policy_scope(Attribute).where(product_class: @product_class).order(:name)
    authorize Attribute
    respond_to do |format|
      format.html
      format.json { render json: @attributes.as_json(only: %i[id name]) }
    end
  end

  def show
    authorize @attribute
  end

  def new
    @attribute = @product_class.product_class_attributes.build
    authorize @attribute
  end

  def edit
    authorize @attribute
  end

  def create
    @attribute = @product_class.product_class_attributes.build(attribute_params)
    authorize @attribute
    if @attribute.save
      redirect_to product_class_attributes_path(@product_class), notice: "Attribute created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @attribute
    if @attribute.update(attribute_params)
      redirect_to product_class_attributes_path(@product_class), notice: "Attribute updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @attribute
    @attribute.destroy
    redirect_to product_class_attributes_path(@product_class), notice: "Attribute deleted."
  end

  private

  def set_product_class
    @product_class = ProductClass.find(params[:product_class_id])
  end

  def set_attribute
    @attribute = @product_class.product_class_attributes.find(params[:id])
  end

  def attribute_params
    params.expect(attribute: [:name])
  end
end
