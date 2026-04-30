import { Controller } from "@hotwired/stimulus"
import { formatCurrency } from "utils/currency"

// Per-row product typeahead: searches by SKU or name, dispatches product:selected on pick
export default class extends Controller {
  static targets = ["input", "productId", "dropdown", "unitDefinition", "unitPrice", "defaultPriceDisplay", "qty", "description"]

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
    this._debounceTimer = setTimeout(() => this.fetch(q), 200)
  }

  async fetch(q) {
    try {
      const url = `/api/v1/catalogs/products?q[name_or_sku_cont]=${encodeURIComponent(q)}`
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
      const res = await fetch(url, {
        headers: { "Accept": "application/json", "X-CSRF-Token": csrfToken },
        credentials: "same-origin"
      })
      if (!res.ok) throw new Error("Network error")
      const data = await res.json()
      this.renderDropdown(data.results || [])
    } catch {
      this.hideDropdown()
    }
  }

  renderDropdown(products) {
    const dd = this.dropdownTarget
    dd.innerHTML = ""

    // Position fixed to escape overflow-x-auto table wrapper
    const rect = this.inputTarget.getBoundingClientRect()
    dd.style.position = "fixed"
    dd.style.top = `${rect.bottom + 2}px`
    dd.style.left = `${rect.left}px`
    dd.style.width = `${Math.max(rect.width, 288)}px`

    if (products.length === 0) {
      dd.innerHTML = `<div class="px-3 py-2 text-sm text-gray-400">No products found.</div>`
    } else {
      products.forEach(p => {
        const item = document.createElement("div")
        item.className = "px-3 py-2 text-sm text-gray-800 hover:bg-blue-50 cursor-pointer"
        item.innerHTML = `
          <span class="font-mono text-xs text-gray-500">${this.escape(p.sku)}</span>
          <span class="ml-2 font-medium">${this.escape(p.name)}</span>
          <span class="ml-auto text-gray-400 text-xs">฿${formatCurrency(p.price)}</span>
        `
        item.style.display = "flex"
        item.style.justifyContent = "space-between"
        item.style.alignItems = "center"
        item.addEventListener("mousedown", (e) => { e.preventDefault(); this.selectProduct(p) })
        dd.appendChild(item)
      })
    }
    dd.classList.remove("hidden")
  }

  selectProduct(product) {
    this.inputTarget.value      = `${product.sku} — ${product.name}`
    this.productIdTarget.value  = product.id
    this.hideDropdown()

    // Populate unit definitions dropdown
    if (this.hasUnitDefinitionTarget) {
      const sel = this.unitDefinitionTarget
      sel.innerHTML = ""
      const defs = product.unit_definitions || []
      defs.forEach(ud => {
        const opt = document.createElement("option")
        opt.value = ud.id
        opt.textContent = ud.name
        opt.dataset.ratio = ud.ratio
        sel.appendChild(opt)
      })
      // Default to the first option (largest ratio since sorted desc)
      if (defs.length > 0) {
        sel.value = defs[0].id
        sel.dataset.currentRatio = defs[0].ratio
      }
    }

    if (this.hasQtyTarget && !this.qtyTarget.value) {
      this.qtyTarget.value = "1"
    }

    this.dispatch("selected", {
      detail: {
        product_id:      product.id,
        unit_definitions: product.unit_definitions || [],
        default_price:   product.price,
        description:     product.description || "",
        sku:             product.sku,
        name:            product.name
      },
      bubbles: true
    })
  }

  updateUnitPrice(price) {
    if (this.hasUnitPriceTarget) {
      this.unitPriceTarget.value = price
      this.unitPriceTarget.dispatchEvent(new Event("input", { bubbles: true }))
    }
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
