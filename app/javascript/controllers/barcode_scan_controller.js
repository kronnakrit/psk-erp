import { Controller } from "@hotwired/stimulus"

const STATUS_LABELS = {
  Dr: "Draft",
  Pd: "Paid",
  Cp: "Completed",
  Cc: "Cancelled",
}

const STATUS_BADGE_CLASSES = {
  Dr: "bg-gray-100 text-gray-700",
  Pd: "bg-green-100 text-green-700",
  Cp: "bg-blue-100 text-blue-700",
  Cc: "bg-red-100 text-red-700",
}

export default class extends Controller {
  static targets = ["input", "tableBody", "emptyRow", "paidBtn", "completeBtn", "alert", "bulkForm", "hiddenInputs", "statusInput"]

  connect() {
    this.scannedOrders = [] // [{ id, order_number, customer_name, status, grand_total }]
    this.inputTarget.focus()
  }

  handleEnter(event) {
    event.preventDefault()
    const raw = this.inputTarget.value.trim()
    if (!raw) return
    this.inputTarget.value = ""
    this.#lookup(raw)
  }

  markAllPaid() {
    this.#submitBulk("Pd")
  }

  markAllComplete() {
    this.#submitBulk("Cp")
  }

  removeRow(event) {
    const orderNumber = event.currentTarget.dataset.orderNumber
    this.scannedOrders = this.scannedOrders.filter(o => o.order_number !== orderNumber)
    const row = this.tableBodyTarget.querySelector(`[data-order-number="${orderNumber}"]`)
    if (row) row.remove()
    this.#updateButtonState()
    if (this.scannedOrders.length === 0) this.#showEmptyRow()
  }

  // ── Private ────────────────────────────────────────────────────────────────

  async #lookup(orderNumber) {
    const url = `/orders/find_by_number?q=${encodeURIComponent(orderNumber)}`
    try {
      const response = await fetch(url, {
        headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
      })

      if (response.status === 404) {
        this.#showAlert(`Order ${orderNumber} not found`, "error")
        return
      }

      const data = await response.json()

      if (this.scannedOrders.some(o => o.order_number === data.order_number)) {
        this.#showAlert(`Order ${data.order_number} already scanned`, "warning")
        return
      }

      this.scannedOrders.push(data)
      this.#appendRow(data)
      this.#hideEmptyRow()
      this.#updateButtonState()
      this.#hideAlert()
    } catch {
      this.#showAlert("Network error — please try again", "error")
    }
  }

  #appendRow(order) {
    const badgeClasses = STATUS_BADGE_CLASSES[order.status] || "bg-gray-100 text-gray-700"
    const statusLabel  = STATUS_LABELS[order.status] || order.status
    const cancelledWarning = order.status === "Cc"
      ? `<span class="ml-2 text-xs text-red-500 font-medium">(will be skipped)</span>`
      : ""

    const tr = document.createElement("tr")
    tr.dataset.orderNumber = order.order_number
    tr.innerHTML = `
      <td class="px-4 py-3 font-mono text-gray-900">${order.order_number}</td>
      <td class="px-4 py-3 text-gray-700">${order.customer_name || "—"}</td>
      <td class="px-4 py-3">
        <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${badgeClasses}">
          ${statusLabel}
        </span>${cancelledWarning}
      </td>
      <td class="px-4 py-3 text-right text-gray-900">${this.#formatCurrency(order.grand_total)}</td>
      <td class="px-4 py-3 text-right">
        <button type="button"
                class="text-sm text-red-500 hover:text-red-700"
                data-order-number="${order.order_number}"
                data-action="click->barcode-scan#removeRow">
          Remove
        </button>
      </td>
    `
    this.tableBodyTarget.appendChild(tr)
  }

  #submitBulk(status) {
    const eligible = this.scannedOrders.filter(o => o.status !== "Cc")
    if (eligible.length === 0) {
      this.#showAlert("No eligible orders to update (all are cancelled).", "error")
      return
    }

    // Clear previous hidden inputs
    this.hiddenInputsTarget.innerHTML = ""

    eligible.forEach(order => {
      const input = document.createElement("input")
      input.type  = "hidden"
      input.name  = "ids[]"
      input.value = order.id
      this.hiddenInputsTarget.appendChild(input)
    })

    this.statusInputTarget.value = status
    this.bulkFormTarget.submit()
  }

  #updateButtonState() {
    const hasOrders = this.scannedOrders.length > 0
    this.paidBtnTarget.disabled     = !hasOrders
    this.completeBtnTarget.disabled = !hasOrders
  }

  #showEmptyRow() {
    if (this.hasEmptyRowTarget) this.emptyRowTarget.classList.remove("hidden")
  }

  #hideEmptyRow() {
    if (this.hasEmptyRowTarget) this.emptyRowTarget.classList.add("hidden")
  }

  #showAlert(message, type) {
    const el = this.alertTarget
    el.textContent = message
    el.className = [
      "mb-4 px-4 py-3 rounded-md text-sm font-medium",
      type === "error"   ? "bg-red-50 text-red-700 border border-red-200" :
      type === "warning" ? "bg-yellow-50 text-yellow-700 border border-yellow-200" :
                           "bg-blue-50 text-blue-700 border border-blue-200",
    ].join(" ")
  }

  #hideAlert() {
    this.alertTarget.className = "hidden mb-4 px-4 py-3 rounded-md text-sm font-medium"
  }

  #formatCurrency(value) {
    if (value == null) return "—"
    return Number(value).toLocaleString("th-TH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }
}
