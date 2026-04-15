module Api
  module V1
    class CountriesController < ApplicationController
      skip_after_action :verify_authorized
      skip_after_action :verify_policy_scoped

      respond_to :json

      def index
        @countries = Country.order(:printable_name)
        render json: { countries: @countries.map { |c| country_json(c) } }
      end

      def show
        @country = Country.find(params[:id])
        render json: country_json(@country)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Not Found" }, status: :not_found
      end

      private

      def country_json(country)
        {
          iso_3166_1_a2: country.iso_3166_1_a2,
          iso_3166_1_a3: country.iso_3166_1_a3,
          iso_3166_1_numeric: country.iso_3166_1_numeric,
          printable_name: country.printable_name,
          name: country.name
        }
      end
    end
  end
end
