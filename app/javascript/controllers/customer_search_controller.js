import { Controller } from "@hotwired/stimulus"

// Customer typeahead: searches by name or telephone, dispatches customer:selected on pick
export default class extends Controller {
  static targets = ["input", "hidden", "dropdown", "display"]
  static values  = { url: String }

  _debounceTimer = null

  connect() {
    document.addEventListener("click", this._onOutsideClick.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this._onOutsideClick.bind(this))
  }

  onInput(event) {
    clearTimeout(this._debounceTimer)
    const q = event.target.value.trim()
    if (q.length < 2) { this.hideDropdown(); return }
    this._debounceTimer = setTimeout(() => this.fetch(q), 300)
  }

  async fetch(q) {
    try {
      const url = `/api/v1/customers/search?q=${encodeURIComponent(q)}`
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
      const res = await fetch(url, {
        headers: { "Accept": "application/json", "X-CSRF-Token": csrfToken },
        credentials: "same-origin"
      })
      if (!res.ok) throw new Error("Network error")
      const customers = await res.json()
      this.renderDropdown(customers)
    } catch {
      this.renderError()
    }
  }

  renderDropdown(customers) {
    const dd = this.dropdownTarget
    dd.innerHTML = ""
    if (customers.length === 0) {
      dd.innerHTML = `<div class="px-3 py-2 text-sm text-gray-400">No customers found.</div>`
    } else {
      customers.forEach(c => {
        const item = document.createElement("div")
        item.className = "px-3 py-2 text-sm text-gray-800 hover:bg-blue-50 cursor-pointer flex justify-between items-center gap-2"
        item.innerHTML = `<span class="font-medium">${this.escape(c.full_name)}</span><span class="text-gray-400 text-xs">${this.escape((c.telephones || []).join(", ") || c.telephone || "")}</span>`
        item.addEventListener("mousedown", (e) => { e.preventDefault(); this.select(c) })
        dd.appendChild(item)
      })
    }
    dd.classList.remove("hidden")
  }

  renderError() {
    const dd = this.dropdownTarget
    dd.innerHTML = `<div class="px-3 py-2 text-sm text-red-500">Search failed — try again.</div>`
    dd.classList.remove("hidden")
  }

  select(customer) {
    this.hiddenTarget.value = customer.id
    this.inputTarget.value  = customer.full_name
    this.hideDropdown()
    this.dispatch("selected", {
      detail: {
        id: customer.id,
        telephone: customer.telephone || (customer.telephones && customer.telephones[0]) || "",
        address: customer.address || "",
        logistic_company_id: customer.logistic_company_id
      }
    })
  }

  hideDropdown() {
    this.dropdownTarget.classList.add("hidden")
    this.dropdownTarget.innerHTML = ""
  }

  _onOutsideClick(e) {
    if (!this.element.contains(e.target)) this.hideDropdown()
  }

  escape(str) {
    const map = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" }
    return String(str).replace(/[&<>"']/g, m => map[m])
  }
}
