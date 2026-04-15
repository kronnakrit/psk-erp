# frozen_string_literal: true

module Api
  module V1
    module Catalogs
      class ProductsController < Api::V1::BaseController
        def index
          @ransack = Product.where(product_type: %w[Sa Pr])
                            .includes(:vendor, :brand, :product_class, :product_categories)
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
          children = product.children.includes(:vendor, :brand)
          render json: { results: children.map { |c| serialize_product(c) } }
        end

        def child
          child = Product.find(params[:id])
          render json: serialize_product(child)
        end

        def advance_search
          @ransack = Product.where(product_type: %w[Sa Pr])
                            .includes(:vendor, :brand, :product_class, :product_categories)
                            .ransack(params[:q])
          render json: { results: @ransack.result.map { |p| serialize_product(p) } }
        end

        def last_price
          product_id = params[:id].to_i
          customer_id = params[:customer_id].to_i
          product = Product.find(product_id)
          last_selling = Product.last_selling_price_for(product_id: product_id, customer_id: customer_id)
          render json: { last_price: last_selling, default_price: product.price }
        end

        def filters
          scope = Product.all
          scope = scope.where(enable_stock: true) if params[:has_stock].to_s == "true"
          render json: { results: scope.map { |p| serialize_product(p) } }
        end

        private

        def serialize_product(product)
          {
            id: product.id,
            sku: product.sku,
            barcode: product.barcode,
            name: product.name,
            description: product.description.presence || "",
            product_type: product.product_type,
            unit: product.unit,
            price: product.price,
            enable_stock: product.enable_stock,
            vendor_id: product.vendor_id,
            brand_id: product.brand_id,
            product_class_id: product.product_class_id,
            parent_id: product.parent_id
          }
        end
      end
    end
  end
end
