# frozen_string_literal: true

# Builds an Excel invoice for a single order.
# Usage: OrderExcelService.new(order).build => Axlsx::Package
class OrderExcelService
  MONEY_FORMAT = "#,##0.00"
  HEADER_BG    = "1E3A5F"
  HEADER_FG    = "FFFFFF"
  SECTION_BG   = "EBF5FF"
  SUMMARY_COLS = [nil, nil, nil, nil].freeze

  def initialize(order)
    @order   = order
    @gt      = ::GrandTotalCalculator.new(order).call
    @lines   = order.order_lines.includes(:product).order(:idx, :id)
    @package = Axlsx::Package.new
  end

  def build
    @package.workbook.add_worksheet(name: "Invoice") do |sheet|
      init_styles(sheet.workbook)
      add_header_rows(sheet)
      add_body_rows(sheet)
      add_summary_rows(sheet)
      sheet.column_widths 5, 35, 10, 10, 18, 18
    end
    @package
  end

  private

  def init_styles(workbook)
    @style_title       = workbook.styles.add_style(b: true, sz: 14, alignment: { horizontal: :left })
    @style_heading     = workbook.styles.add_style(
      b: true, fg_color: HEADER_FG, bg_color: HEADER_BG,
      border: Axlsx::STYLE_THIN_BORDER,
      alignment: { horizontal: :center, wrap_text: true }
    )
    @style_label       = workbook.styles.add_style(b: true, sz: 11)
    @style_value       = workbook.styles.add_style(sz: 11)
    @style_money       = workbook.styles.add_style(format_code: MONEY_FORMAT, alignment: { horizontal: :right })
    @style_total       = workbook.styles.add_style(b: true, format_code: MONEY_FORMAT,
                                                   bg_color: SECTION_BG, alignment: { horizontal: :right })
    @style_total_label = workbook.styles.add_style(b: true, bg_color: SECTION_BG)
    @style_center      = workbook.styles.add_style(alignment: { horizontal: :center })
  end

  def add_header_rows(sheet)
    sheet.add_row ["PSK Baby — Invoice"], style: @style_title
    sheet.add_row []
    sheet.add_row ["Date:",         nil, @order.running_date&.strftime("%d/%m/%Y")],
                  style: [@style_label, nil, @style_value]
    sheet.add_row ["Order Number:", nil, @order.order_number], style: [@style_label, nil, @style_value]
    sheet.add_row ["Customer:",     nil, @order.customer&.fullname], style: [@style_label, nil, @style_value]
    sheet.add_row ["Telephone:",    nil, @order.telephone.presence || "—"], style: [@style_label, nil, @style_value]
    sheet.add_row ["Address:",      nil, @order.address.presence || "—"], style: [@style_label, nil, @style_value]
    sheet.add_row ["Remark:",       nil, @order.remark.presence || "—"], style: [@style_label, nil, @style_value]
    sheet.add_row []
    sheet.add_row ["#", "Description", "Unit", "Qty", "Unit Price (฿)", "Total (฿)"],
                  style: Array.new(6, @style_heading)
  end

  def add_body_rows(sheet)
    @lines.each_with_index do |line, index|
      sheet.add_row [
        index + 1,
        line.product&.name,
        line.unit,
        line.quantity,
        line.unit_price,
        line.total_price
      ], style: [@style_center, @style_value, @style_center, @style_center, @style_money, @style_money],
         types: %i[integer string string float float float]
    end
  end

  def add_summary_rows(sheet)
    sheet.add_row []
    add_summary_row(sheet, "Subtotal", @gt[:total_price].to_f)
    add_discount_row(sheet)
    add_vat_rows(sheet)
    add_wht_row(sheet)
    add_summary_row(sheet, "Grand Total", @gt[:grand_total].to_f)
  end

  def add_summary_row(sheet, label, amount)
    sheet.add_row [*SUMMARY_COLS, label, amount],
                  style: [nil, nil, nil, nil, @style_total_label, @style_total]
  end

  def add_discount_row(sheet)
    return unless @gt[:discount_amount].nonzero?

    add_summary_row(sheet, "Discount", -@gt[:discount_amount].to_f)
  end

  def add_vat_rows(sheet)
    return unless @order.has_vat?

    add_summary_row(sheet, "Excl. VAT", @gt[:price_excl_vat].to_f)
    add_summary_row(sheet, "VAT (7%)", @gt[:vat_price].to_f)
  end

  def add_wht_row(sheet)
    return unless @order.is_withholding_tax? && @gt[:withholding_tax_amount].nonzero?

    add_summary_row(sheet, "Withholding Tax", -@gt[:withholding_tax_amount].to_f)
  end
end
