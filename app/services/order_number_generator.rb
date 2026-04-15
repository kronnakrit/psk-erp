# frozen_string_literal: true

# Generates a collision-safe order number in YYYYMMDD### format.
# Sequence resets each day. Uses a loop to skip any gaps from deleted orders.
class OrderNumberGenerator
  def initialize(running_date = Time.zone.today)
    @running_date = running_date
  end

  def call
    prefix = @running_date.strftime("%Y%m%d")
    count  = Order.where(running_date: @running_date).count + 1
    loop do
      candidate = "#{prefix}#{count.to_s.rjust(3, '0')}"
      return candidate unless Order.exists?(order_number: candidate)

      count += 1
    end
  end
end
