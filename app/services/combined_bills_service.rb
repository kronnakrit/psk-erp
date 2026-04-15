# frozen_string_literal: true

# Builds a combined billing statement Excel for multiple orders of the same customer.
# Returns { package:, customer_name: } or { error: } if validation fails.
class CombinedBillsService
  MONEY_FORMAT = "#,##0.00"
  SECTION_BG   = "EBF5FF"

  def initialize(order_ids:, prepared_by:)
    @order_ids   = Array(order_ids)
    @prepared_by = prepared_by
  end

  def build
    @orders = Order.where(id: @order_ids).includes(:customer).order(:running_date, :order_number)
    return { error: "No orders found." } if @orders.empty?

    customers = @orders.map(&:customer_id).uniq
    return { error: "All orders must belong to the same customer." } if customers.size > 1

    @customer = @orders.first.customer
    package   = build_package
    { package: package, customer_name: @customer.fullname }
  end

  private

  def build_package
    pkg = Axlsx::Package.new
    pkg.workbook.add_worksheet(name: "ใบรวมบิล") do |sheet|
      init_styles(sheet.workbook)
      add_header_rows(sheet)
      add_body_rows(sheet)
      add_summary_rows(sheet)
      sheet.column_widths 6, 25, 20, 20
    end
    pkg
  end

  def init_styles(workbook)
    @style_title  = workbook.styles.add_style(b: true, sz: 14)
    @style_label  = workbook.styles.add_style(b: true)
    @style_value  = workbook.styles.add_style(sz: 11)
    @style_head   = workbook.styles.add_style(b: true, bg_color: "1E3A5F", fg_color: "FFFFFF",
                                              border: Axlsx::STYLE_THIN_BORDER,
                                              alignment: { horizontal: :center })
    @style_center = workbook.styles.add_style(alignment: { horizontal: :center })
    @style_money  = workbook.styles.add_style(format_code: MONEY_FORMAT, alignment: { horizontal: :right })
    @style_total  = workbook.styles.add_style(b: true, format_code: MONEY_FORMAT,
                                              bg_color: SECTION_BG, alignment: { horizontal: :right })
    @style_total_label = workbook.styles.add_style(b: true, bg_color: SECTION_BG)
  end

  def add_header_rows(sheet)
    sheet.add_row ["ใบรวมบิล"], style: @style_title
    sheet.add_row []
    sheet.add_row ["วันที่:", nil, Time.zone.today.strftime("%d/%m/%Y")],
                  style: [@style_label, nil, @style_value]
    sheet.add_row ["ลูกค้า:", nil, @customer.fullname], style: [@style_label, nil, @style_value]
    sheet.add_row ["วันครบกำหนด:", nil, ""], style: [@style_label, nil, @style_value]
    sheet.add_row []
    sheet.add_row ["#", "เลขที่บิล", "วันที่บิล", "จำนวนเงิน (฿)"],
                  style: Array.new(4, @style_head)
  end

  def add_body_rows(sheet)
    @orders.each_with_index do |order, index|
      sheet.add_row [
        index + 1,
        order.order_number,
        order.running_date&.strftime("%d/%m/%Y"),
        order.grand_total.to_f
      ], style: [@style_center, @style_value, @style_center, @style_money],
         types: %i[integer string string float]
    end
  end

  def add_summary_rows(sheet)
    total = @orders.sum(&:grand_total).to_f
    sheet.add_row []
    sheet.add_row ["", "", "รวมทั้งหมด", total],
                  style: [nil, nil, @style_total_label, @style_total]
    sheet.add_row []
    sheet.add_row ["ผู้จัดทำ:", nil, @prepared_by], style: [@style_label, nil, @style_value]
    sheet.add_row ["ผู้รับ:", nil, ""], style: [@style_label, nil, @style_value]
  end
end
