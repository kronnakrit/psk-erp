import { Controller } from "@hotwired/stimulus"
import { formatCurrency, parseCurrency } from "utils/currency"

// Master Stimulus controller for the Purchase Order create/edit form.
// Handles: add/remove lines, auto-fill unit cost from last_purchase_cost API, compute totals.
export default class extends Controller {
  static targets = [
    "linesContainer",
    "lineTemplate",
    "grandTotal",
    // Per-row targets (accessed via element queries within the row)
    "destroyField",
    "qty",
    "unitCost",
    "lineTotal"
  ]

  connect() {
    this.element.addEventListener("order-line-search:selected", this._onProductSelected.bind(this))
    this._recomputeAllTotals()
  }

  disconnect() {
    this.element.removeEventListener("order-line-search:selected", this._onProductSelected.bind(this))
  }

  // ─── Add / Remove lines ───────────────────────────────────────────────────

  addLine() {
    const timestamp = new Date().getTime()
    const html = this.lineTemplateTarget.innerHTML.replace(/NEW_RECORD/g, timestamp)
    this.linesContainerTarget.insertAdjacentHTML("beforeend", html)
    const newRow = this.linesContainerTarget.lastElementChild
    newRow?.querySelector("[data-order-line-search-target='input']")?.focus()
  }

  removeLine(event) {
    const row = event.currentTarget.closest("tr")
    if (!row) return
    const destroyField = row.querySelector("[data-purchase-order-form-target='destroyField']")
    if (destroyField) {
      destroyField.value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
    this._recomputeGrandTotal()
  }

  // ─── Product selected — auto-fill unit cost ───────────────────────────────

  async _onProductSelected(event) {
    const { product_id } = event.detail
    if (!product_id) return

    const row = event.target.closest("tr")
    if (!row) return

    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
      const res = await fetch(`/api/v1/catalogs/products/${product_id}/last_purchase_cost`, {
        headers: { "Accept": "application/json", "X-CSRF-Token": csrfToken },
        credentials: "same-origin"
      })
      if (!res.ok) return
      const data = await res.json()
      if (data.unit_cost != null) {
        const unitCostInput = row.querySelector("[data-purchase-order-form-target='unitCost']")
        if (unitCostInput) {
          unitCostInput.value = parseFloat(data.unit_cost).toFixed(2)
          unitCostInput.dispatchEvent(new Event("input", { bubbles: true }))
        }
      }
    } catch { /* silently ignore */ }
  }

  // ─── Total computation ────────────────────────────────────────────────────

  onLineInputChange(event) {
    const row = event.target.closest("tr")
    if (row) this._recomputeLineTotal(row)
    this._recomputeGrandTotal()
  }

  _recomputeAllTotals() {
    this.linesContainerTarget?.querySelectorAll("tr:not(.hidden)").forEach(row => {
      this._recomputeLineTotal(row)
    })
    this._recomputeGrandTotal()
  }

  _recomputeLineTotal(row) {
    const qty  = parseCurrency(row.querySelector("[data-purchase-order-form-target='qty']")?.value || 0)
    const cost = parseCurrency(row.querySelector("[data-purchase-order-form-target='unitCost']")?.value || 0)
    const el   = row.querySelector("[data-purchase-order-form-target='lineTotal']")
    if (el) el.textContent = `฿${formatCurrency(qty * cost)}`
  }

  _recomputeGrandTotal() {
    let total = 0
    this.linesContainerTarget?.querySelectorAll("tr").forEach(row => {
      const destroyField = row.querySelector("[data-purchase-order-form-target='destroyField']")
      if (destroyField?.value === "1") return
      if (row.classList.contains("hidden")) return
      const qty  = parseCurrency(row.querySelector("[data-purchase-order-form-target='qty']")?.value || 0)
      const cost = parseCurrency(row.querySelector("[data-purchase-order-form-target='unitCost']")?.value || 0)
      total += qty * cost
    })
    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = `฿${formatCurrency(total)}`
    }
  }
}
