# frozen_string_literal: true

class OrderDuplicateService
  ORDER_HEADER_ATTRS = %w[
    customer_id logistic_company_id address telephone
    has_vat is_included_vat discount_price is_discount_percentage
    discount_percentage is_withholding_tax withholding_tax
    logistic_status remark internal_note
  ].freeze

  ORDER_LINE_ATTRS = %w[
    product_id unit quantity unit_price discount_price description remark idx
  ].freeze

  def initialize(source_order, current_user:)
    @source_order = source_order
    @current_user = current_user
  end

  def call
    new_order = build_order
    new_order.save!
    new_order
  end

  private

  def build_order
    attrs = @source_order.attributes.slice(*ORDER_HEADER_ATTRS)
    attrs.merge!(
      status: "Dr",
      running_date: Time.zone.today
    )

    new_order = Order.new(attrs)
    @source_order.order_lines.each do |line|
      new_line_attrs = line.attributes.slice(*ORDER_LINE_ATTRS)
      new_order.order_lines.build(new_line_attrs)
    end

    new_order
  end
end
