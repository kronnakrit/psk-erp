const fmt = new Intl.NumberFormat("en-US", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
})

export function formatCurrency(n) {
  const num = typeof n === "string" ? parseCurrency(n) : Number(n)
  return fmt.format(isNaN(num) ? 0 : num)
}

export function parseCurrency(s) {
  return parseFloat(String(s).replace(/,/g, "")) || 0
}
