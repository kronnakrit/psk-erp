import { Controller } from "@hotwired/stimulus"

// Sidebar overlay toggle (mobile)
export default class extends Controller {
  toggle() {
    const sidebar = document.getElementById("sidebar")
    const overlay = document.getElementById("sidebar-overlay")
    sidebar.classList.toggle("hidden")
    overlay.classList.toggle("hidden")
  }

  close() {
    const sidebar = document.getElementById("sidebar")
    const overlay = document.getElementById("sidebar-overlay")
    sidebar.classList.add("hidden")
    overlay.classList.add("hidden")
  }
}
