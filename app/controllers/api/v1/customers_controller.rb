module Api
  module V1
    class CustomersController < Api::V1::BaseController
      before_action :set_customer, only: %i[show update destroy]

      def index
        @ransack = policy_scope(Customer).includes(:logistic_company, :country).ransack(params[:q])
        @pagy, @customers = pagy(@ransack.result, limit: params.fetch(:per_page, 25).to_i)
        authorize Customer
        render json: {
          customers: @customers.map { |c| customer_json(c) },
          pagination: { page: @pagy.page, pages: @pagy.pages, total: @pagy.count }
        }
      end

      def show
        authorize @customer
        render json: customer_json(@customer)
      end

      def create
        @customer = Customer.new(customer_params)
        authorize @customer
        if @customer.save
          render json: customer_json(@customer), status: :created
        else
          render json: { errors: @customer.errors }, status: :unprocessable_content
        end
      end

      def update
        authorize @customer
        if @customer.update(customer_params)
          render json: customer_json(@customer)
        else
          render json: { errors: @customer.errors }, status: :unprocessable_content
        end
      end

      def destroy
        authorize @customer
        @customer.soft_delete!
        head :no_content
      end

      def filter
        authorize Customer, :index?
        search_text = params[:search_text].to_s.strip
        safe_text = ActiveRecord::Base.sanitize_sql_like(search_text)
        @customers = Customer.where(
          "first_name ILIKE ? OR last_name ILIKE ?",
          "%#{safe_text}%", "%#{safe_text}%"
        ).order(:first_name)
        render json: { customers: @customers.map { |c| customer_json(c) } }
      end

      def search
        authorize Customer, :index?
        q = params[:q].to_s.strip
        safe_q = ActiveRecord::Base.sanitize_sql_like(q)
        customers = policy_scope(Customer)
                    .where("first_name ILIKE ? OR last_name ILIKE ? OR telephone ILIKE ?",
                           "%#{safe_q}%", "%#{safe_q}%", "%#{safe_q}%")
                    .order(:first_name)
                    .limit(20)
        render json: customers.map { |c| customer_json(c) }
      end

      private

      def set_customer
        @customer = Customer.find(params[:id])
      end

      def customer_params
        params.expect(customer: %i[first_name last_name address remark telephone country_id logistic_company_id])
      end

      def customer_json(customer)
        {
          id: customer.id,
          first_name: customer.first_name,
          last_name: customer.last_name,
          full_name: customer.get_fullname,
          address: customer.address,
          remark: customer.remark,
          telephone: customer.telephone,
          country_id: customer.country_id,
          logistic_company_id: customer.logistic_company_id
        }
      end
    end
  end
end
