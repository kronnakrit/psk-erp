import { Controller } from "@hotwired/stimulus"

// Collapsible sidebar group with localStorage persistence
// Usage: data-controller="sidebar-group" data-sidebar-group-key-value="catalog_expanded"
export default class extends Controller {
  static targets = ["items", "chevron"]
  static values  = { key: String }

  connect() {
    const expanded = localStorage.getItem(this.keyValue) !== "false"
    if (expanded) {
      this.itemsTarget.classList.remove("hidden")
      this.chevronTarget.style.transform = "rotate(0deg)"
    } else {
      this.itemsTarget.classList.add("hidden")
      this.chevronTarget.style.transform = "rotate(-90deg)"
    }
  }

  toggle() {
    const hidden = this.itemsTarget.classList.toggle("hidden")
    this.chevronTarget.style.transform = hidden ? "rotate(-90deg)" : "rotate(0deg)"
    localStorage.setItem(this.keyValue, String(!hidden))
  }
}
