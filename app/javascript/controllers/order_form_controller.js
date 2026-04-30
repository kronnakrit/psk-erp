import { Controller } from "@hotwired/stimulus"
import { formatCurrency, parseCurrency } from "utils/currency"

/**
 * Master Stimulus controller for the order form.
 * Coordinates: customer autofill, logistic autofill, line total calculation,
 * summary computation, VAT/WHT/discount toggles, tab-to-add-line.
 */
export default class extends Controller {
  static targets = [
    // Header
    "customerId", "telephone", "address", "logisticSelect",
    // Summary toggles
    "vatCheckbox", "includedVatCheckbox", "includedVatRow",
    "whtCheckbox", "whtInput", "whtRow",
    "discountPctCheckbox", "discountPctInput", "discountAmtInput", "discountRow",
    // Summary display
    "summarySubtotal", "summaryDiscount", "summaryDiscountRow",
    "summaryAfterDiscount", "summaryAfterDiscountRow",
    "summaryExclVat", "summaryExclVatRow",
    "summaryVat", "summaryVatRow",
    "summaryWht", "summaryWhtRow",
    "summaryGrandTotal",
    // Order lines
    "linesContainer", "lineTemplate"
  ]

  connect() {
    this.element.addEventListener("customer-search:selected", this._onCustomerSelected.bind(this))
    this.element.addEventListener("order-line-search:selected", this._onProductSelected.bind(this))
    this.element.addEventListener("submit", this._sanitizeBeforeSubmit.bind(this))
    this._initToggles()
    this.computeOrderSummary()
  }

  // ─── Customer autofill ────────────────────────────────────────────────────

  _onCustomerSelected(event) {
    const { id, telephone, address, logistic_company_id } = event.detail
    if (this.hasCustomerIdTarget)  this.customerIdTarget.value  = id
    if (this.hasTelephoneTarget)   this.telephoneTarget.value   = telephone
    if (this.hasAddressTarget)     this.addressTarget.value     = address
    this.autofillLogistic(logistic_company_id)
  }

  autofillLogistic(logisticCompanyId) {
    if (!this.hasLogisticSelectTarget) return
    const sel = this.logisticSelectTarget
    if (sel.dataset.manuallyChanged === "true") return
    sel.value = logisticCompanyId || ""
  }

  logisticManuallyChanged() {
    if (this.hasLogisticSelectTarget) {
      this.logisticSelectTarget.dataset.manuallyChanged = "true"
    }
  }

  // ─── Product autofill ─────────────────────────────────────────────────────

  async _onProductSelected(event) {
    const { product_id, unit_definitions, default_price, description } = event.detail
    const row = event.target.closest("tr")
    if (!row) return

    // Autofill description (only when empty or previously autofilled by product selection)
    const descriptionInput = row.querySelector("[data-order-line-search-target='description']")
    if (descriptionInput && !descriptionInput.dataset.userEdited) {
      descriptionInput.value = description || ""
      descriptionInput.addEventListener("input", () => { descriptionInput.dataset.userEdited = "true" }, { once: true })
    }

    // Set unit price: try to fetch last selling price for this customer first
    const customerId = this.hasCustomerIdTarget ? this.customerIdTarget.value : null
    const unitDefSelect = row.querySelector("[data-order-line-search-target='unitDefinition']")
    const selectedUnitDefId = unitDefSelect?.value
    let price = default_price
    const hintLabel = `Default: ฿${formatCurrency(default_price)}`

    if (customerId && product_id) {
      try {
        const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
        let url = `/api/v1/catalogs/products/${product_id}/last_price/${customerId}`
        if (selectedUnitDefId) url += `?unit_definition_id=${selectedUnitDefId}`
        const res = await fetch(url, {
          headers: { "Accept": "application/json", "X-CSRF-Token": csrfToken },
          credentials: "same-origin"
        })
        if (res.ok) {
          const data = await res.json()
          if (data.last_price != null) {
            price = parseFloat(data.last_price)
          } else {
            price = parseFloat(data.default_price ?? default_price)
          }
        }
      } catch { /* silence — fall back to default_price */ }
    }

    // Update unit price input
    const unitPriceInput = row.querySelector("[data-price-input]")
    if (unitPriceInput) {
      unitPriceInput.value = price
      unitPriceInput.dispatchEvent(new Event("input", { bubbles: true }))
    }

    // Show price hint below unit price
    const defaultDisplay = row.querySelector("[data-default-price-display]")
    if (defaultDisplay) {
      defaultDisplay.textContent = hintLabel
      defaultDisplay.classList.remove("hidden")
    }

    // Set qty to 1 if empty
    const qtyInput = row.querySelector("[data-qty-input]")
    if (qtyInput && !qtyInput.value) qtyInput.value = "1"

    // Sync unit price via search controller (triggers input event for recompute)
    const searchCtrl = this.application.getControllerForElementAndIdentifier(
      row.querySelector("[data-controller='order-line-search']"),
      "order-line-search"
    )
    if (searchCtrl) searchCtrl.updateUnitPrice(price)

    this.computeLineTotal(row)
    this.computeOrderSummary()
  }

  // ─── Unit Definition change (ratio-based price recalculation) ────────────

  onUnitDefinitionChange(event) {
    const sel = event.target
    const row = sel.closest("tr")
    if (!row) return

    const newRatio    = parseFloat(sel.selectedOptions[0]?.dataset.ratio || 1)
    const currentRatio = parseFloat(sel.dataset.currentRatio || 1)
    if (currentRatio === 0) return

    const unitPriceInput = row.querySelector("[data-price-input]")
    if (unitPriceInput && currentRatio !== newRatio) {
      const currentPrice = parseCurrency(unitPriceInput.value || 0)
      const newPrice     = currentPrice * (newRatio / currentRatio)
      unitPriceInput.value = newPrice
      unitPriceInput.dispatchEvent(new Event("input", { bubbles: true }))
    }

    sel.dataset.currentRatio = newRatio
    this.computeLineTotal(row)
    this.computeOrderSummary()
  }

  // ─── Line total computation ───────────────────────────────────────────────

  computeLineTotal(row) {
    const qty       = parseCurrency(row.querySelector("[data-qty-input]")?.value || 0)
    const unitPrice = parseCurrency(row.querySelector("[data-price-input]")?.value || 0)
    const discount  = parseCurrency(row.querySelector("[data-discount-input]")?.value || 0)
    const total     = Math.max(0, qty * unitPrice - discount)
    const display   = row.querySelector("[data-line-total]")
    if (display) display.textContent = `฿${formatCurrency(total)}`
  }

  onLineInputChange(event) {
    const row = event.target.closest("tr")
    if (row) this.computeLineTotal(row)
    this.computeOrderSummary()
  }

  // ─── Tab-to-add-line ──────────────────────────────────────────────────────

  onDiscountKeydown(event) {
    if (event.key !== "Tab" || event.shiftKey) return
    const allRows = Array.from(this.linesContainerTarget.querySelectorAll("tr:not(.hidden)"))
      .filter(r => r.querySelector("[data-order-line-target='destroyField']")?.value !== "1")
    const currentRow = event.target.closest("tr")
    const isLast = allRows[allRows.length - 1] === currentRow
    if (isLast) {
      event.preventDefault()
      this.addLine()
    }
  }

  // ─── Add / Remove lines ───────────────────────────────────────────────────

  addLine() {
    const timestamp = new Date().getTime()
    const html = this.lineTemplateTarget.innerHTML.replace(/NEW_LINE_RECORD/g, timestamp)
    this.linesContainerTarget.insertAdjacentHTML("beforeend", html)
    const newRow = this.linesContainerTarget.lastElementChild
    const productInput = newRow.querySelector("[data-order-line-search-target='input']")
    if (productInput) productInput.focus()
  }

  removeLine(event) {
    const row = event.currentTarget.closest("tr")
    if (!row) return
    const destroyField = row.querySelector("[data-order-line-target='destroyField']")
    if (destroyField) {
      destroyField.value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
    this.computeOrderSummary()
  }

  // ─── Toggle helpers ───────────────────────────────────────────────────────

  _initToggles() {
    this.toggleVat()
    this.toggleWht()
    this.toggleDiscountMode()
  }

  toggleVat() {
    const hasVat = this.hasVatCheckboxTarget && this.vatCheckboxTarget.checked
    if (this.hasIncludedVatRowTarget) {
      this.includedVatRowTarget.classList.toggle("hidden", !hasVat)
      if (!hasVat && this.hasIncludedVatCheckboxTarget) {
        this.includedVatCheckboxTarget.checked = false
      }
    }
    this.computeOrderSummary()
  }

  toggleWht() {
    const hasWht = this.hasWhtCheckboxTarget && this.whtCheckboxTarget.checked
    if (this.hasWhtRowTarget) this.whtRowTarget.classList.toggle("hidden", !hasWht)
    this.computeOrderSummary()
  }

  toggleDiscountMode() {
    const isPct = this.hasDiscountPctCheckboxTarget && this.discountPctCheckboxTarget.checked
    if (this.hasDiscountPctInputTarget) this.discountPctInputTarget.closest("[data-discount-pct-row]")?.classList.toggle("hidden", !isPct)
    if (this.hasDiscountAmtInputTarget) this.discountAmtInputTarget.closest("[data-discount-amt-row]")?.classList.toggle("hidden", isPct)
    this.computeOrderSummary()
  }

  // ─── Order summary ─────────────────────────────────────────────────────────

  computeOrderSummary() {
    // Collect visible (non-destroyed) rows
    const rows = Array.from(this.linesContainerTarget?.querySelectorAll("tr") || [])
      .filter(r => r.querySelector("[data-order-line-target='destroyField']")?.value !== "1")

    let subtotal = 0
    rows.forEach(row => {
      const qty       = parseCurrency(row.querySelector("[data-qty-input]")?.value || 0)
      const unitPrice = parseCurrency(row.querySelector("[data-price-input]")?.value || 0)
      const discount  = parseCurrency(row.querySelector("[data-discount-input]")?.value || 0)
      subtotal += Math.max(0, qty * unitPrice - discount)
    })

    const hasVat     = this.hasVatCheckboxTarget     && this.vatCheckboxTarget.checked
    const isInclVat  = hasVat && this.hasIncludedVatCheckboxTarget && this.includedVatCheckboxTarget.checked
    const hasWht     = this.hasWhtCheckboxTarget     && this.whtCheckboxTarget.checked
    const whtPct     = hasWht && this.hasWhtInputTarget ? parseCurrency(this.whtInputTarget.value) : 0
    const isDiscPct  = this.hasDiscountPctCheckboxTarget && this.discountPctCheckboxTarget.checked

    let discountAmt = 0
    if (isDiscPct) {
      const pct = this.hasDiscountPctInputTarget ? parseCurrency(this.discountPctInputTarget.value) : 0
      discountAmt = subtotal * Math.min(pct, 100) / 100
    } else {
      discountAmt = this.hasDiscountAmtInputTarget ? parseCurrency(this.discountAmtInputTarget.value) : 0
    }

    const priceAfterDiscount = Math.max(0, subtotal - discountAmt)

    let exclVat = 0, vatAmt = 0
    if (hasVat) {
      if (isInclVat) {
        exclVat = priceAfterDiscount / 1.07
        vatAmt  = priceAfterDiscount - exclVat
      } else {
        exclVat = priceAfterDiscount
        vatAmt  = priceAfterDiscount * 0.07
      }
    }

    const priceWithVat  = hasVat ? (isInclVat ? priceAfterDiscount : priceAfterDiscount + vatAmt) : priceAfterDiscount
    const whtAmt        = hasWht ? priceWithVat * whtPct / 100 : 0
    const grandTotal    = Math.max(0, priceWithVat - whtAmt)

    // Update display
    this._setText("summarySubtotal", `฿${formatCurrency(subtotal)}`)

    const showDiscount = discountAmt > 0
    this._setText("summaryDiscount", `−฿${formatCurrency(discountAmt)}`)
    this._toggleRow("summaryDiscountRow", showDiscount)
    this._setText("summaryAfterDiscount", `฿${formatCurrency(priceAfterDiscount)}`)
    this._toggleRow("summaryAfterDiscountRow", showDiscount)

    if (hasVat) {
      this._setText("summaryExclVat", `฿${formatCurrency(exclVat)}`)
      this._toggleRow("summaryExclVatRow", true)
      this._setText("summaryVat", `฿${formatCurrency(vatAmt)}`)
      this._toggleRow("summaryVatRow", true)
    } else {
      this._toggleRow("summaryExclVatRow", false)
      this._toggleRow("summaryVatRow", false)
    }

    if (hasWht && whtAmt > 0) {
      this._setText("summaryWht", `−฿${formatCurrency(whtAmt)}`)
      this._toggleRow("summaryWhtRow", true)
    } else {
      this._toggleRow("summaryWhtRow", false)
    }

    this._setText("summaryGrandTotal", `฿${formatCurrency(grandTotal)}`)
  }

  _setText(targetName, text) {
    const capName = targetName.charAt(0).toUpperCase() + targetName.slice(1)
    const hasFn = `has${capName}Target`
    const getterFn = `${targetName}Target`
    if (this[hasFn]) this[getterFn].textContent = text
  }

  _toggleRow(targetName, show) {
    const capName = targetName.charAt(0).toUpperCase() + targetName.slice(1)
    const hasFn = `has${capName}Target`
    const getterFn = `${targetName}Target`
    if (this[hasFn]) this[getterFn].classList.toggle("hidden", !show)
  }

  // ─── Numeric input formatting ─────────────────────────────────────────────

  onNumericFocus(event) {
    const raw = parseCurrency(event.target.value)
    event.target.value = raw === 0 ? "" : String(raw)
  }

  onNumericBlur(event) {
    const raw = parseCurrency(event.target.value)
    if (!isNaN(raw)) event.target.value = formatCurrency(raw)
  }

  // Strip comma formatting from decimal inputs before form submit
  _sanitizeBeforeSubmit() {
    this.element.querySelectorAll("input[inputmode='decimal']").forEach(input => {
      const raw = parseCurrency(input.value)
      input.value = String(raw)
    })
  }
}
