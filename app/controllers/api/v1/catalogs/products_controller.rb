# frozen_string_literal: true

module Api
  module V1
    module Catalogs
      class ProductsController < Api::V1::BaseController
        def index
          @ransack = Product.where(product_type: %w[Sa Pr])
                            .includes(:brand, :product_class, :product_categories,
                                      { unit_group: :unit_definitions })
                            .ransack(params[:q])
          @ransack.sorts = "name asc" if @ransack.sorts.empty?
          products = @ransack.result
          render json: {
            results: products.map { |p| serialize_product(p) }
          }
        end

        def show
          product = Product.find(params[:id])
          render json: serialize_product(product)
        end

        def parent
          product = Product.find(params[:id])
          children = product.children.includes(:brand)
          render json: { results: children.map { |c| serialize_product(c) } }
        end

        def child
          child = Product.find(params[:id])
          render json: serialize_product(child)
        end

        def advance_search
          @ransack = Product.where(product_type: %w[Sa Pr])
                            .includes(:brand, :product_class, :product_categories,
                                      { unit_group: :unit_definitions })
                            .ransack(params[:q])
          render json: { results: @ransack.result.map { |p| serialize_product(p) } }
        end

        def last_price
          product_id = params[:id].to_i
          customer_id = params[:customer_id].to_i
          product = Product.find(product_id)

          last_selling = if params[:unit_definition_id].present?
                           Product.last_selling_price_for(
                             product_id: product_id,
                             customer_id: customer_id,
                             unit_definition_id: params[:unit_definition_id].to_i
                           )
                         else
                           Product.last_selling_price_for(product_id: product_id, customer_id: customer_id)
                         end

          render json: { last_price: last_selling, default_price: product.price }
        end

        def filters
          scope = Product.includes({ unit_group: :unit_definitions })
          scope = scope.where(enable_stock: true) if params[:has_stock].to_s == "true"
          render json: { results: scope.map { |p| serialize_product(p) } }
        end

        def lots
          product = Product.find(params[:id])
          unless product.enable_stock
            render json: [] and return
          end

          lots = product.product_lots
                        .where(status: ProductLot::STATUS_ACTIVE)
                        .order(:received_date, :id)
          render json: lots.map { |lot|
            {
              id: lot.id,
              lot_number: lot.lot_number,
              received_date: lot.received_date,
              remaining_quantity: lot.remaining_quantity,
              unit_cost: lot.unit_cost
            }
          }
        end

        def last_purchase_cost
          product = Product.find(params[:id])
          po_line = PurchaseOrderLine.joins(:purchase_order)
                                    .where(product: product,
                                           purchase_orders: { status: "Cf" })
                                    .order("purchase_orders.created_at DESC")
                                    .first
          unit_cost = po_line ? po_line.unit_cost : product.cost
          render json: { unit_cost: unit_cost }
        end

        def fifo_cost
          product  = Product.find(params[:id])
          quantity = params[:quantity]

          if quantity.blank?
            render json: { error: "quantity is required" }, status: :unprocessable_content and return
          end

          qty = quantity.to_d
          if qty <= 0
            render json: { error: "quantity must be greater than 0" }, status: :unprocessable_content and return
          end

          if params[:unit_definition_id].present?
            unit_def = UnitDefinition.find(params[:unit_definition_id])
            qty = qty * unit_def.ratio
          end

          result = FifoLotAllocationService.new(product, qty).call(dry_run: true)
          render json: {
            weighted_avg_cost: result.weighted_avg_cost,
            has_phantom: result.phantom_qty > 0,
            allocations: result.allocations.map { |a|
              {
                lot_number: a.lot.lot_number,
                allocated_qty: a.qty,
                unit_cost: a.unit_cost
              }
            }
          }
        end

        private

        def serialize_product(product)
          group = product.effective_unit_group
          unit_defs = group ? group.unit_definitions.order(ratio: :asc).map { |ud|
            { id: ud.id, name: ud.name, ratio: ud.ratio }
          } : []
          {
            id: product.id,
            sku: product.sku,
            barcode: product.barcode,
            name: product.name,
            description: product.description.presence || "",
            product_type: product.product_type,
            unit_group_id: product.unit_group_id,
            unit_group_name: product.unit_group&.name,
            price: product.price,
            enable_stock: product.enable_stock,
            brand_id: product.brand_id,
            product_class_id: product.product_class_id,
            parent_id: product.parent_id,
            unit_definitions: unit_defs
          }
        end
      end
    end
  end
end
