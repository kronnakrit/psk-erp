# frozen_string_literal: true

# Generates a collision-safe PO number in PO-YYYYMMDD-XXXX format.
# Sequence resets each day.
class PurchaseOrderNumberGenerator
  def initialize(po_date = Time.zone.today)
    @po_date = po_date
  end

  def call
    prefix = "PO-#{@po_date.strftime('%Y%m%d')}-"
    count  = PurchaseOrder.where(po_date: @po_date).count + 1
    loop do
      candidate = "#{prefix}#{count.to_s.rjust(4, '0')}"
      return candidate unless PurchaseOrder.exists?(po_number: candidate)

      count += 1
    end
  end
end
