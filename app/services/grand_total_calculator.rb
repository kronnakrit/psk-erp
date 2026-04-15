# frozen_string_literal: true

# Implements the 7-step grand total calculation formula from §9.2 of requirements.md.
# All monetary values rounded to 2 decimal places with half-up rounding.
class GrandTotalCalculator
  HALF_UP = BigDecimal::ROUND_HALF_UP
  VAT_RATE = BigDecimal("0.07")

  def initialize(order)
    @order = order
  end

  def call
    total_price         = order_lines_sum
    discount_amount     = calc_discount(total_price)
    price_with_discount = (total_price - discount_amount).round(2, HALF_UP)
    price_excl_vat      = calc_price_excl_vat(price_with_discount)
    vat_price           = calc_vat(price_with_discount, price_excl_vat)
    wht_amount          = calc_withholding_tax(price_excl_vat)
    grand_total         = (price_excl_vat + vat_price - wht_amount).round(2, HALF_UP)

    {
      total_price: total_price,
      discount_amount: discount_amount,
      price_with_discount: price_with_discount,
      price_excl_vat: price_excl_vat,
      vat_price: vat_price,
      withholding_tax_amount: wht_amount,
      grand_total: grand_total
    }
  end

  private

  def order_lines_sum
    bd(@order.order_lines.sum(:total_price))
  end

  def calc_discount(total_price)
    if @order.is_discount_percentage?
      (total_price * (bd(@order.discount_percentage) / 100)).round(2, HALF_UP)
    else
      bd(@order.discount_price)
    end
  end

  def calc_price_excl_vat(price_with_discount)
    if @order.is_included_vat?
      (price_with_discount / (1 + VAT_RATE)).round(2, HALF_UP)
    else
      price_with_discount
    end
  end

  def calc_vat(price_with_discount, price_excl_vat)
    return BigDecimal("0") unless @order.has_vat?

    if @order.is_included_vat?
      (price_with_discount - price_excl_vat).round(2, HALF_UP)
    else
      (price_with_discount * VAT_RATE).round(2, HALF_UP)
    end
  end

  def calc_withholding_tax(price_excl_vat)
    return BigDecimal("0") unless @order.is_withholding_tax?

    (price_excl_vat * (bd(@order.withholding_tax) / 100)).round(2, HALF_UP)
  end

  def bd(value)
    BigDecimal(value.to_s)
  end
end
