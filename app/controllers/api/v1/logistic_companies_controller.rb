module Api
  module V1
    class LogisticCompaniesController < Api::V1::BaseController
      before_action :set_logistic_company, only: %i[show update destroy]

      def index
        @ransack = policy_scope(LogisticCompany).ransack(params[:q])
        @pagy, @logistic_companies = pagy(@ransack.result, limit: params.fetch(:per_page, 25).to_i)
        authorize LogisticCompany
        render json: {
          logistic_companies: @logistic_companies.map { |lc| logistic_company_json(lc) },
          pagination: { page: @pagy.page, pages: @pagy.pages, total: @pagy.count }
        }
      end

      def show
        authorize @logistic_company
        render json: logistic_company_json(@logistic_company)
      end

      def create
        @logistic_company = LogisticCompany.new(logistic_company_params)
        authorize @logistic_company
        if @logistic_company.save
          render json: logistic_company_json(@logistic_company), status: :created
        else
          render json: { errors: @logistic_company.errors }, status: :unprocessable_content
        end
      end

      def update
        authorize @logistic_company
        if @logistic_company.update(logistic_company_params)
          render json: logistic_company_json(@logistic_company)
        else
          render json: { errors: @logistic_company.errors }, status: :unprocessable_content
        end
      end

      def destroy
        authorize @logistic_company
        @logistic_company.destroy!
        head :no_content
      end

      def filter
        authorize LogisticCompany, :index?
        search_text = params[:search_text].to_s.strip
        @logistic_companies = LogisticCompany.where("name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(search_text)}%").order(:name)
        render json: { logistic_companies: @logistic_companies.map { |lc| logistic_company_json(lc) } }
      end

      private

      def set_logistic_company
        @logistic_company = LogisticCompany.find(params[:id])
      end

      def logistic_company_params
        params.expect(logistic_company: %i[name address remark telephone])
      end

      def logistic_company_json(company)
        {
          id: company.id,
          name: company.name,
          address: company.address,
          remark: company.remark,
          telephone: company.telephone
        }
      end
    end
  end
end
