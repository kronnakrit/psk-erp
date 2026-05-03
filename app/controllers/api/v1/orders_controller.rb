# frozen_string_literal: true

module Api
  module V1
    class OrdersController < BaseController # rubocop:disable Metrics/ClassLength
      before_action :set_order, only: %i[show update destroy]

      # GET /api/v1/orders
      def index
        orders = policy_scope(Order).includes(:customer, :logistic_company).order(running_date: :desc)
        @pagy, orders_page = pagy(orders)
        render json: { orders: orders_page.as_json(include: %i[customer logistic_company]),
                       pagy: pagy_metadata(@pagy) }
      end

      # GET /api/v1/orders/draft
      def draft
        @pagy, orders = pagy(policy_scope(Order).draft.includes(:customer).order(running_date: :desc))
        render json: { orders: orders.as_json(include: :customer), pagy: pagy_metadata(@pagy) }
      end

      # GET /api/v1/orders/paid
      def paid
        @pagy, orders = pagy(policy_scope(Order).paid.includes(:customer).order(running_date: :desc))
        render json: { orders: orders.as_json(include: :customer), pagy: pagy_metadata(@pagy) }
      end

      # GET /api/v1/orders/completed
      def completed
        @pagy, orders = pagy(policy_scope(Order).completed.includes(:customer).order(running_date: :desc))
        render json: { orders: orders.as_json(include: :customer), pagy: pagy_metadata(@pagy) }
      end

      # GET /api/v1/orders/cancelled
      def cancelled
        @pagy, orders = pagy(policy_scope(Order).cancelled.includes(:customer).order(running_date: :desc))
        render json: { orders: orders.as_json(include: :customer), pagy: pagy_metadata(@pagy) }
      end

      # GET /api/v1/orders/dashboard
      def dashboard
        today = Time.zone.today
        render json: {
          today_count: Order.for_date(today).count,
          draft_count: Order.draft.count,
          monthly_revenue: Order.completed
                           .where(running_date: today.all_month)
                                .sum(:grand_total)
        }
      end

      # GET /api/v1/orders/:id
      def show
        render json: @order.as_json(
          include: {
            customer: {},
            logistic_company: {},
            order_lines: { include: :product },
            order_images: {}
          }
        )
      end

      # POST /api/v1/orders
      def create
        order = Order.new(order_params)
        if order.save
          render json: order, status: :created
        else
          render json: { errors: order.errors }, status: :unprocessable_content
        end
      end

      # PATCH /api/v1/orders/:id
      def update
        if @order.update(order_params)
          render json: @order
        else
          render json: { errors: @order.errors }, status: :unprocessable_content
        end
      end

      # DELETE /api/v1/orders/:id
      def destroy
        authorize @order
        @order.destroy
        head :no_content
      end

      # POST /api/v1/orders/advance_search
      def advance_search
        ransack = policy_scope(Order).includes(:customer).ransack(params[:q])
        @pagy, orders = pagy(ransack.result)
        render json: { orders: orders.as_json(include: :customer), pagy: pagy_metadata(@pagy) }
      end

      # POST /api/v1/orders/filters
      def filters # rubocop:disable Metrics/AbcSize
        scope = policy_scope(Order).includes(:customer)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(logistic_status: params[:logistic_status]) if params[:logistic_status].present?
        scope = scope.where(running_date: date_range) if params[:from].present? || params[:to].present?
        @pagy, orders = pagy(scope.order(running_date: :desc))
        render json: { orders: orders.as_json(include: :customer), pagy: pagy_metadata(@pagy) }
      end

      # POST /api/v1/orders/bulk_update_status
      def bulk_update_status
        authorize Order, :bulk_update_status?

        ids             = params[:ids]
        is_selected_all = params[:is_selected_all].to_s == "true"

        if ids.present? && is_selected_all
          render json: { error: "Provide either ids or is_selected_all, not both" }, status: :bad_request
          return
        end

        new_status = params[:status]
        unless Order::STATUSES.include?(new_status)
          render json: { error: "Invalid status" }, status: :unprocessable_content
          return
        end

        if is_selected_all
          policy_scope(Order).update_all(status: new_status) # rubocop:disable Rails/SkipsModelValidations
        else
          policy_scope(Order).where(id: Array(ids)).update_all(status: new_status) # rubocop:disable Rails/SkipsModelValidations
        end

        render json: { message: "Status updated" }
      end

      # POST /api/v1/orders/customer_report
      def customer_report
        authorize Order, :report?
        start_date = Date.parse(params[:start_date])
        end_date   = Date.parse(params[:end_date])
        package    = ::CustomerReportService.new(start_date: start_date, end_date: end_date).build
        send_data package.to_stream.read,
                  type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                  disposition: "attachment",
                  filename: "customer_report#{start_date}-#{end_date}.xlsx"
      rescue Date::Error
        render json: { error: "Invalid date format. Use YYYY-MM-DD." }, status: :unprocessable_content
      end

      # POST /api/v1/orders/sales_report
      def sales_report
        authorize Order, :report?
        start_date = Date.parse(params[:start_date])
        end_date   = Date.parse(params[:end_date])
        package    = ::SalesReportService.new(start_date: start_date, end_date: end_date).build
        send_data package.to_stream.read,
                  type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                  disposition: "attachment",
                  filename: "sales_report#{start_date}-#{end_date}.xlsx"
      rescue Date::Error
        render json: { error: "Invalid date format. Use YYYY-MM-DD." }, status: :unprocessable_content
      end

      # POST /api/v1/orders/report_order
      def report_order
        authorize Order, :report?
        start_date = Date.parse(params[:start_date])
        end_date   = Date.parse(params[:end_date])
        render json: ::SalesGraphService.new(start_date: start_date, end_date: end_date).call
      rescue Date::Error
        render json: { error: "Invalid date format. Use YYYY-MM-DD." }, status: :unprocessable_content
      end

      private

      def set_order
        @order = Order.find(params[:id])
      end

      def order_params
        params.expect(order: [
                        :customer_id, :logistic_company_id, :telephone, :address,
                        :has_vat, :is_included_vat, :discount_price, :is_discount_percentage,
                        :discount_percentage, :remark, :internal_note, :status, :running_date,
                        :is_withholding_tax, :withholding_tax, :logistic_status,
                        { order_lines_attributes: [%i[
                          id product_id unit quantity unit_price
                          discount_price description remark idx _destroy
                        ]] }
                      ])
      end

      def date_range
        from = params[:from].present? ? Date.parse(params[:from]) : Date.new(1900, 1, 1)
        to   = params[:to].present?   ? Date.parse(params[:to])   : Time.zone.today
        from..to
      end
    end
  end
end
