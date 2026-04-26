import { Controller } from "@hotwired/stimulus"

// Shows a live preview of the equivalent base-unit amount as the user types.
// e.g. "2" with "dozen (ratio=12)" selected → "= 24 pcs"
//
// Usage:
//   data-controller="unit-preview"
//   data-unit-preview-base-unit-name-value="pcs"
//
// Targets:
//   quantity — the numeric input
//   unit     — the <select> with <option data-ratio="...">
//   preview  — the <span> to update with the computed text
export default class extends Controller {
  static targets = ["quantity", "unit", "preview"]
  static values  = { baseUnitName: String }

  connect() {
    this.update()
  }

  update() {
    if (!this.hasQuantityTarget || !this.hasUnitTarget || !this.hasPreviewTarget) return

    const qty   = parseFloat(this.quantityTarget.value)
    const select = this.unitTarget
    const selectedOption = select.options[select.selectedIndex]
    const ratio = selectedOption ? parseInt(selectedOption.dataset.ratio || "1", 10) : 1

    if (isNaN(qty) || qty <= 0) {
      this.previewTarget.textContent = ""
      return
    }

    const baseAmount = qty * ratio
    const baseUnitName = this.baseUnitNameValue || "units"

    this.previewTarget.textContent = `= ${baseAmount} ${baseUnitName}`
  }
}
