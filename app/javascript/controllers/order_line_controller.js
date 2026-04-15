import { Controller } from "@hotwired/stimulus"

// Manages nested order line fields: add and remove rows
export default class extends Controller {
  static targets = ["container", "template", "destroyField"]

  connect() {}

  addLine() {
    const timestamp = new Date().getTime()
    const template  = this.templateTarget.innerHTML.replace(/NEW_LINE_RECORD/g, timestamp)
    this.containerTarget.insertAdjacentHTML("beforeend", template)
  }

  removeLine(event) {
    const row = event.currentTarget.closest("tr")
    if (!row) return

    // If the row has a destroy field (persisted record), mark for deletion
    const destroyField = row.querySelector("[data-order-line-target='destroyField']")
    if (destroyField) {
      destroyField.value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
  }
}
