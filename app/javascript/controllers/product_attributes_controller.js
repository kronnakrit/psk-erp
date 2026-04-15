import { Controller } from "@hotwired/stimulus"

// Dynamically loads custom attributes for the selected product class
// and renders text inputs for setting their values.
export default class extends Controller {
  static targets = ["container", "productClassSelect"]
  static values  = { existingAttributes: Array }

  connect() {
    const productClassId = this.productClassSelectTarget.value
    if (productClassId) {
      this.loadAttributes(productClassId)
    }
  }

  productClassChanged(event) {
    const productClassId = event.target.value
    this.containerTarget.innerHTML = ""
    if (productClassId) {
      this.loadAttributes(productClassId)
    }
  }

  async loadAttributes(productClassId) {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    const response = await fetch(`/product_classes/${productClassId}/attributes.json`, {
      headers: {
        "Accept": "application/json",
        "X-CSRF-Token": csrfToken
      },
      credentials: "same-origin"
    })

    if (!response.ok) return

    const attributes = await response.json()
    this.renderAttributeFields(attributes)
  }

  renderAttributeFields(attributes) {
    const container = this.containerTarget
    container.innerHTML = ""

    if (attributes.length === 0) {
      container.innerHTML = `<p class="text-sm text-gray-400 italic">No custom attributes defined for this product class.</p>`
      return
    }

    attributes.forEach((attr, index) => {
      const existing = this.existingAttributesValue.find(ea => ea.attribute_id === attr.id)
      const existingId = existing ? existing.id : ""
      const existingValue = existing ? existing.value : ""

      const wrapper = document.createElement("div")
      wrapper.innerHTML = `
        <label class="block text-xs font-medium text-gray-700 mb-1">${this.escapeHtml(attr.name)}</label>
        <input type="hidden" name="product[product_attributes_attributes][${index}][attribute_id]" value="${attr.id}">
        <input type="hidden" name="product[product_attributes_attributes][${index}][id]" value="${existingId}">
        <input
          type="text"
          name="product[product_attributes_attributes][${index}][value]"
          value="${this.escapeHtml(existingValue)}"
          class="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
      `
      container.appendChild(wrapper)
    })
  }

  escapeHtml(str) {
    const map = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" }
    return String(str).replace(/[&<>"']/g, m => map[m])
  }
}
