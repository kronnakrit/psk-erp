import { Controller } from "@hotwired/stimulus"

// Controls the invoice preview modal on the new invoice page.
// Reads selected order checkboxes, renders a grouped summary, then submits the form.
export default class extends Controller {
  static targets = ["modal", "summary"]

  // Open the preview modal — called via data-action="click->invoice-preview#open"
  open (event) {
    event.preventDefault()

    const checked = this.element.querySelectorAll("input[name='order_ids[]']:checked")
    if (checked.length === 0) {
      alert("Please select at least one order.")
      return
    }

    const orders = Array.from(checked).map(cb => {
      const row = cb.closest('tr')
      return {
        id:       cb.value,
        number:   row ? row.cells[1]?.textContent?.trim() : cb.value,
        customer: row ? (row.dataset.customerName || "—") : "—",
        total:    row ? (row.dataset.grandTotal || "—") : "—"
      }
    })

    this.summaryTarget.innerHTML = this._buildPreviewHtml(orders)
    this.modalTarget.classList.remove("hidden")
  }

  // Confirm — submit the real form
  confirm () {
    const form = document.getElementById("create_invoice_form")
    if (form) form.requestSubmit()
  }

  // Close the modal without submitting
  close () {
    this.modalTarget.classList.add("hidden")
  }

  // --- private ---

  _buildPreviewHtml (orders) {
    const rows = orders.map(o => `
      <tr class="border-b border-gray-100">
        <td class="py-1.5 pr-4 text-sm text-gray-700">${this._escape(o.number)}</td>
        <td class="py-1.5 pr-4 text-sm text-gray-600">${this._escape(o.customer)}</td>
        <td class="py-1.5 text-sm text-gray-700 text-right">${this._escape(this._formatCurrency(o.total))}</td>
      </tr>`).join("")

    return `
      <p class="text-sm text-gray-600 mb-3">
        You are about to create an invoice with <strong>${orders.length}</strong> order(s).
      </p>
      <table class="w-full">
        <thead>
          <tr class="border-b border-gray-200">
            <th class="pb-2 text-left text-xs font-medium text-gray-500 uppercase">Order</th>
            <th class="pb-2 text-left text-xs font-medium text-gray-500 uppercase">Customer</th>
            <th class="pb-2 text-right text-xs font-medium text-gray-500 uppercase">Total</th>
          </tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>`
  }

  _formatCurrency (value) {
    const num = parseFloat(value)
    if (isNaN(num)) return value
    return "฿" + num.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ",")
  }

  _escape (str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
