import { Controller } from "@hotwired/stimulus"

// Handles PO line form: auto-fills unit_cost via last_purchase_cost API when a product is selected
export default class extends Controller {
  static targets = ["productId", "unitDefinition", "quantity", "unitCost"]

  async onProductSelected(event) {
    const productId = event.detail?.product_id
    if (!productId) return

    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
      const res = await fetch(`/api/v1/catalogs/products/${productId}/last_purchase_cost`, {
        headers: { "Accept": "application/json", "X-CSRF-Token": csrfToken },
        credentials: "same-origin"
      })
      if (!res.ok) return
      const data = await res.json()
      if (data.unit_cost != null && this.hasUnitCostTarget) {
        this.unitCostTarget.value = parseFloat(data.unit_cost).toFixed(2)
      }
    } catch {
      // silently ignore
    }
  }
}
