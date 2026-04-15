# frozen_string_literal: true

# Generates an Excel sales report for completed orders within a date range.
# Groups by created_by (staff), sums grand_total, counts bills, sorted descending by total.
# Usage: SalesReportService.new(start_date:, end_date:).build => Axlsx::Package
class SalesReportService
  MONEY_FORMAT = "#,##0.00"
  HEADER_BG    = "1E3A5F"
  HEADER_FG    = "FFFFFF"

  def initialize(start_date:, end_date:)
    @start_date = start_date
    @end_date   = end_date
  end

  def build
    @rows = query_data
    build_package
  end

  private

  def query_data
    Order.completed
         .where(running_date: @start_date..@end_date)
         .joins("LEFT JOIN profiles ON profiles.user_id = orders.created_by_id")
         .group("orders.created_by_id", "profiles.first_name", "profiles.last_name",
                "profiles.user_id")
         .select("orders.created_by_id,
                  profiles.first_name,
                  profiles.last_name,
                  SUM(orders.grand_total) AS total_amount,
                  COUNT(orders.id) AS bill_count")
         .order(total_amount: :desc)
  end

  def build_package
    pkg = Axlsx::Package.new
    pkg.workbook.add_worksheet(name: "Sales Report") do |sheet|
      init_styles(sheet.workbook)
      add_header(sheet)
      add_data_rows(sheet)
      sheet.column_widths 6, 30, 25, 15
    end
    pkg
  end

  def init_styles(workbook)
    @style_title   = workbook.styles.add_style(b: true, sz: 14)
    @style_heading = workbook.styles.add_style(b: true, fg_color: HEADER_FG, bg_color: HEADER_BG,
                                               border: Axlsx::STYLE_THIN_BORDER,
                                               alignment: { horizontal: :center })
    @style_center  = workbook.styles.add_style(alignment: { horizontal: :center })
    @style_money   = workbook.styles.add_style(format_code: MONEY_FORMAT, alignment: { horizontal: :right })
  end

  def add_header(sheet)
    sheet.add_row ["Sales Summary Report"], style: @style_title
    sheet.add_row ["Period: #{@start_date} — #{@end_date}"]
    sheet.add_row []
    sheet.add_row ["No.", "Staff Name", "Total Sales Amount (฿)", "Number of Bills"],
                  style: Array.new(4, @style_heading)
  end

  def add_data_rows(sheet)
    @rows.each_with_index do |row, index|
      fullname = [row.first_name, row.last_name].compact.join(" ").presence || "Unknown"
      sheet.add_row [
        index + 1,
        fullname,
        row.total_amount.to_f,
        row.bill_count.to_i
      ], style: [@style_center, nil, @style_money, @style_center],
         types: %i[integer string float integer]
    end
  end
end
