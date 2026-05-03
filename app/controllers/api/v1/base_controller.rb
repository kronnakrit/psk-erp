module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!

      # Pundit verification is handled per-action in API controllers
      skip_after_action :verify_authorized, :verify_policy_scoped

      respond_to :json

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "Not Found" }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { errors: e.record.errors }, status: :unprocessable_content
      end

      private

      def pagy_metadata(pagy)
        {
          page: pagy.page,
          per_page: pagy.limit,
          total: pagy.count,
          pages: pagy.pages
        }
      end
    end
  end
end
