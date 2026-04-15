# frozen_string_literal: true

# PriceMonitorService detects customer+product pairs whose unit_price has changed
# by >= threshold_pct% over the rolling window_days.
#
# Usage:
#   PriceMonitorService.new.call
#   => Array of OpenStruct with: customer, product, first_price, last_price,
#      first_order_number, last_order_number, first_order_date, last_order_date, change_pct
class PriceMonitorService
  def call(threshold_pct: 10, window_days: 365)
    rows = fetch_rows(window_days)
    customers, products = preload_associations(rows)
    build_results(rows, customers, products, threshold_pct)
  end

  private

  def fetch_rows(window_days)
    window_start = window_days.days.ago.to_date
    OrderLine
      .joins(:order, :product, order: :customer)
      .where(orders: { running_date: window_start.. })
      .where.not(orders: { status: "Cc" })
      .select(
        "orders.customer_id",
        "order_lines.product_id",
        "order_lines.unit_price",
        "orders.running_date",
        "orders.order_number",
        "orders.id AS order_id"
      )
      .to_a
  end

  def preload_associations(rows)
    customer_ids = rows.map(&:customer_id).uniq
    product_ids  = rows.map(&:product_id).uniq
    customers    = Customer.where(id: customer_ids).index_by(&:id)
    products     = Product.where(id: product_ids).index_by(&:id)
    [customers, products]
  end

  def build_results(rows, customers, products, threshold_pct)
    grouped = rows.group_by { |r| [r.customer_id, r.product_id] }
    grouped.filter_map do |(customer_id, product_id), group_rows|
      build_entry(group_rows, customers[customer_id], products[product_id], threshold_pct)
    end
  end

  def build_entry(group_rows, customer, product, threshold_pct)
    sorted      = group_rows.sort_by(&:running_date)
    first_row   = sorted.first
    last_row    = sorted.last

    return nil if first_row.running_date == last_row.running_date

    first_price = first_row.unit_price.to_f
    last_price  = last_row.unit_price.to_f
    return nil if first_price.zero?

    change_pct = ((last_price - first_price) / first_price) * 100
    return nil if change_pct.abs < threshold_pct

    OpenStruct.new( # rubocop:disable Style/OpenStructUse
      customer: customer,
      product: product,
      first_price: first_price,
      last_price: last_price,
      first_order_number: first_row.order_number,
      last_order_number: last_row.order_number,
      first_order_date: first_row.running_date,
      last_order_date: last_row.running_date,
      change_pct: change_pct.round(2)
    )
  end
end
