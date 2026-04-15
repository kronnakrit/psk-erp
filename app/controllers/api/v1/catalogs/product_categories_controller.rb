module Api
  module V1
    module Catalogs
      class ProductCategoriesController < Api::V1::BaseController
        def list_product_categories
          categories = ProductCategory.order(:name)
          render json: { results: categories.map { |c| { id: c.id, name: c.name } } }
        end
      end
    end
  end
end
