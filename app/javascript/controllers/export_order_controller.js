import { Controller } from "@hotwired/stimulus"

// Fetches a short-lived signed token from export_token_order_path, then
// triggers a direct browser download via the tokenised download endpoint.
// Bypasses Turbo so the file download works correctly inside Turbo Frames.
//
// Usage:
//   <div data-controller="export-order"
//        data-export-order-token-url-value="<%= export_token_order_path(@order) %>"
//        data-export-order-download-url-value="<%= download_orders_path %>">
//     <button data-action="click->export-order#download">Export Invoice</button>
//   </div>
export default class extends Controller {
  static values = {
    tokenUrl:    String,
    downloadUrl: String
  }

  async download(event) {
    event.preventDefault()
    const btn = event.currentTarget
    const originalText = btn.textContent
    btn.disabled = true
    btn.textContent = "Generating…"

    try {
      const resp = await fetch(this.tokenUrlValue, {
        headers: {
          "Accept":           "application/json",
          "X-CSRF-Token":     document.querySelector('meta[name="csrf-token"]')?.content ?? "",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (!resp.ok) throw new Error(`Token request failed: ${resp.status}`)
      const { token } = await resp.json()

      // Trigger a full browser navigation so the file downloads natively
      window.location.href = `${this.downloadUrlValue}?token=${encodeURIComponent(token)}`
    } catch (err) {
      console.error("[export-order]", err)
      alert("Could not generate export. Please try again.")
    } finally {
      btn.disabled = false
      btn.textContent = originalText
    }
  }
}
