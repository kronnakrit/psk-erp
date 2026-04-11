import { Controller } from "@hotwired/stimulus"

// Auto-dismisses flash alerts after 5 seconds
// Usage: data-controller="flash"
export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.dismiss(), 5000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.style.transition = "opacity 300ms ease"
    this.element.style.opacity = "0"
    setTimeout(() => this.element.remove(), 300)
  }
}
