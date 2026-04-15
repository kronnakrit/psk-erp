import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["barcode"]

  connect() {
    const barcodeEl = this.barcodeTarget
    const orderNumber = barcodeEl.dataset.orderNumber

    if (window.JsBarcode && orderNumber) {
      window.JsBarcode(barcodeEl, orderNumber, {
        format: "CODE128",
        displayValue: false,
        width: 2,
        height: 60,
        margin: 0
      })
    }

    // Inject default A4 page size
    this.#injectPageStyle("A4", "10mm")
  }

  selectSize(event) {
    const size = event.target.value
    const margin = size === "A5" ? "8mm" : "10mm"
    this.#injectPageStyle(size, margin)
  }

  printPage() {
    window.print()
  }

  #injectPageStyle(size, margin) {
    let styleTag = document.getElementById("paper-size-style")
    if (!styleTag) {
      styleTag = document.createElement("style")
      styleTag.id = "paper-size-style"
      document.head.appendChild(styleTag)
    }
    styleTag.textContent = `@page { size: ${size}; margin: ${margin}; }`
  }
}
