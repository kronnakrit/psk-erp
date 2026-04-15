class DashboardController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_authorized, :verify_policy_scoped

  def index
    @price_alerts = policy(Order).price_monitor? ? PriceMonitorService.new.call : []

    return unless permission?("see_sale_graph")

    start_date = 11.months.ago.beginning_of_month.to_date
    end_date   = Time.zone.today.end_of_month.to_date
    graph_data = Order.completed
                      .where(running_date: start_date..end_date)
                      .group_by_month(:running_date, range: start_date..end_date)
                      .sum(:grand_total)
    @chart_data = graph_data.transform_keys { |date| date.strftime("%b %Y") }
  end
end
