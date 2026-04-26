# frozen_string_literal: true

class UnitDefinitionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_unit_group
  after_action :verify_authorized

  def create
    @unit_definition = @unit_group.unit_definitions.build(unit_definition_params)
    authorize @unit_definition

    if @unit_definition.save
      flash.now[:notice] = "Unit definition added."
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @unit_group, notice: "Unit definition added." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "unit_definition_form",
            partial: "unit_definitions/form",
            locals: { unit_group: @unit_group, unit_definition: @unit_definition }
          ), status: :unprocessable_content
        end
        format.html { render "unit_groups/show", status: :unprocessable_content }
      end
    end
  end

  def destroy
    @unit_definition = @unit_group.unit_definitions.find(params[:id])
    authorize @unit_definition

    if @unit_definition.destroy
      flash.now[:notice] = "Unit definition removed."
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @unit_group, notice: "Unit definition removed." }
      end
    else
      render_destroy_error
    end
  end

  def set_main
    @unit_definition = @unit_group.unit_definitions.find(params[:id])
    authorize @unit_definition

    UnitDefinition.transaction do
      UnitDefinition.where(unit_group_id: @unit_group.id).update_all(is_main: false) # rubocop:disable Rails/SkipsModelValidations
      @unit_definition.update_column(:is_main, true) # rubocop:disable Rails/SkipsModelValidations
    end

    flash.now[:notice] = "Main unit updated."
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @unit_group, notice: "Main unit updated." }
    end
  rescue ActiveRecord::StatementInvalid => e
    flash.now[:alert] = e.message
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.prepend("flash", partial: "layouts/flash"),
               status: :unprocessable_content
      end
      format.html { redirect_to @unit_group, alert: e.message }
    end
  end

  private

  def render_destroy_error
    flash.now[:alert] = @unit_definition.errors.full_messages.to_sentence
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.prepend("flash", partial: "layouts/flash"), status: :unprocessable_content
      end
      format.html { redirect_to @unit_group, alert: @unit_definition.errors.full_messages.to_sentence }
    end
  end

  def set_unit_group
    @unit_group = UnitGroup.find(params[:unit_group_id])
  end

  def unit_definition_params
    params.expect(unit_definition: %i[name ratio])
  end
end
