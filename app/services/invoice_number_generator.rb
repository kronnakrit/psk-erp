# frozen_string_literal: true

# Generates a collision-safe invoice number in INV-YYYYMMDD### format.
# Sequence resets each day. Uses a loop to skip any gaps from cancelled invoices.
class InvoiceNumberGenerator
  def initialize(invoice_date = Time.zone.today)
    @invoice_date = invoice_date
  end

  def call
    prefix = "INV-#{@invoice_date.strftime('%Y%m%d')}"
    count  = Invoice.where(invoice_date: @invoice_date).count + 1
    loop do
      candidate = "#{prefix}#{count.to_s.rjust(3, '0')}"
      return candidate unless Invoice.exists?(invoice_number: candidate)

      count += 1
    end
  end
end
