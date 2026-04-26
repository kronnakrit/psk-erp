# frozen_string_literal: true

# Builds a multi-sheet Excel workbook for a collection of orders.
# Each order occupies one worksheet matching the reference sample layout.
# Usage:
#   service = BulkOrderExcelExportService.new(orders)
#   package = service.build  # => Axlsx::Package
class BulkOrderExcelExportService # rubocop:disable Metrics/ClassLength
  MONEY_FORMAT = "#,##0.00"
  HEADER_BG    = "1E3A5F"
  HEADER_FG    = "FFFFFF"
  MAX_SHEET_NAME_LEN = 31

  def initialize(orders)
    @orders  = orders
    @package = Axlsx::Package.new
  end

  def build
    used_names = []
    @orders.each do |order|
      raw_name  = sheet_name_for(order)
      safe_name = deduplicate_sheet_name(raw_name, used_names)
      used_names << safe_name

      @package.workbook.add_worksheet(name: safe_name) do |sheet|
        init_styles(sheet.workbook) unless @styles_initialised
        @styles_initialised = true
        add_header_rows(sheet, order)
        add_column_header_row(sheet)
        add_data_rows(sheet, order.order_lines.order(:idx, :id))
        add_footer_rows(sheet, order)
        sheet.column_widths 4, 10, 10, 45, 15, 15
      end
    end
    @package
  end

  private

  def sheet_name_for(order)
    "#{order.order_number} - #{order.customer.fullname}"[0, MAX_SHEET_NAME_LEN]
  end

  def deduplicate_sheet_name(name, used_names)
    return name unless used_names.include?(name)

    counter = 2
    loop do
      suffix    = " (#{counter})"
      candidate = "#{name[0, MAX_SHEET_NAME_LEN - suffix.length]}#{suffix}"
      return candidate unless used_names.include?(candidate)

      counter += 1
    end
  end

  def init_styles(workbook)
    @style_label   = workbook.styles.add_style(b: true, sz: 11)
    @style_value   = workbook.styles.add_style(sz: 11)
    @style_heading = workbook.styles.add_style(
      b: true, fg_color: HEADER_FG, bg_color: HEADER_BG,
      border: Axlsx::STYLE_THIN_BORDER,
      alignment: { horizontal: :center, wrap_text: true }
    )
    @style_money      = workbook.styles.add_style(format_code: MONEY_FORMAT, alignment: { horizontal: :right })
    @style_total      = workbook.styles.add_style(b: true, format_code: MONEY_FORMAT, alignment: { horizontal: :right })
    @style_total_label = workbook.styles.add_style(b: true)
    @style_center = workbook.styles.add_style(alignment: { horizontal: :center })
  end

  def add_header_rows(sheet, order)
    sheet.add_row ["Date",     order.running_date&.strftime("%d-%b-%Y")],
                  style: [@style_label, @style_value]
    sheet.add_row ["No.",      order.order_number],
                  style: [@style_label, @style_value]
    sheet.add_row ["Customer", order.customer&.fullname],
                  style: [@style_label, @style_value]
    sheet.add_row ["Tel.",     order.telephone.presence || "—"],
                  style: [@style_label, @style_value]
    sheet.add_row ["Address",  order.address.presence || "—"],
                  style: [@style_label, @style_value]
    sheet.add_row ["Remark",   order.remark.to_s],
                  style: [@style_label, @style_value]
    sheet.add_row []
  end

  def add_column_header_row(sheet)
    sheet.add_row(
      ["NO", "Quantity", "Unit", "Description", "Price per Unit", "Total"],
      style: Array.new(6, @style_heading)
    )
  end

  def add_data_rows(sheet, order_lines)
    order_lines.each_with_index do |line, index|
      description = [line.product&.name, line.product&.description.presence].compact.join(" ")
      sheet.add_row [
        index + 1,
        line.quantity.to_f,
        line.unit_definition&.name,
        description,
        line.unit_price.to_f,
        line.total_price.to_f
      ], style: [@style_center, @style_money, @style_center, @style_value, @style_money, @style_money],
         types: %i[integer float string string float float]
    end
  end

  def add_footer_rows(sheet, order)
    totals = ::GrandTotalCalculator.new(order).call
    sheet.add_row []
    footer_rows(order, totals).each do |label, value, bold|
      label_style = bold ? @style_total_label : @style_label
      value_style = bold ? @style_total       : @style_money
      sheet.add_row(["", "", "", "", label, value],
                    style: [nil, nil, nil, nil, label_style, value_style])
    end
  end

  def footer_rows(order, totals)
    rows = [["Total", totals[:total_price].to_f, false]]
    rows.concat(discount_row(totals))
    rows.concat(vat_rows(order, totals))
    rows.concat(wht_row(order, totals))
    rows << ["Grand Total", totals[:grand_total].to_f, true]
    rows
  end

  def discount_row(totals)
    return [] if totals[:discount_amount].to_f.zero?

    [["Discount", -totals[:discount_amount].to_f, false]]
  end

  def vat_rows(order, totals)
    return [] unless order.has_vat?

    [
      ["Price excl. VAT", totals[:price_excl_vat].to_f, false],
      ["VAT 7%", totals[:vat_price].to_f, false]
    ]
  end

  def wht_row(order, totals)
    return [] unless order.is_withholding_tax? && totals[:withholding_tax_amount].to_f.nonzero?

    [["WHT #{order.withholding_tax.to_i}%", -totals[:withholding_tax_amount].to_f, false]]
  end
end
