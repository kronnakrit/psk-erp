import { Controller } from "@hotwired/stimulus"

// Fires a dismissable banner when a Turbo Stream replaces an upload row
// with a terminal status (completed / failed).
export default class extends Controller {
  connect() {
    const status = this.element.dataset.uploadStatus
    if (status === "completed" || status === "failed") {
      this.#showBanner(status)
    }
  }

  #showBanner(status) {
    const banner = document.getElementById("import_notification_banner")
    if (!banner) return

    const processed = this.element.dataset.uploadProcessed || "0"
    const failed    = this.element.dataset.uploadFailed    || "0"

    const isSuccess = status === "completed"
    const colorClass = isSuccess
      ? "bg-green-50 border border-green-200 text-green-800"
      : "bg-red-50 border border-red-200 text-red-800"

    const message = isSuccess
      ? `Import completed: ${processed} rows processed, ${failed} failed.`
      : `Import failed. ${failed} row(s) encountered errors.`

    banner.innerHTML = `
      <div class="flex items-start justify-between rounded-lg px-4 py-3 ${colorClass}">
        <span class="text-sm">${message}</span>
        <button class="ml-4 text-sm font-medium underline" onclick="this.closest('[id]').classList.add('hidden')">
          Dismiss
        </button>
      </div>`
    banner.classList.remove("hidden")
  }
}
