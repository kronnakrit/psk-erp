import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "submitBtn", "form"]

  connect() {
    this.toggle()
    this.formTarget.addEventListener("turbo:submit-start", this.onSubmitStart.bind(this))
    this.formTarget.addEventListener("turbo:submit-end", this.onSubmitEnd.bind(this))
  }

  disconnect() {
    this.formTarget.removeEventListener("turbo:submit-start", this.onSubmitStart.bind(this))
    this.formTarget.removeEventListener("turbo:submit-end", this.onSubmitEnd.bind(this))
  }

  toggle() {
    const hasFile = this.fileInputTarget.files.length > 0
    this.submitBtnTarget.disabled = !hasFile
  }

  onSubmitStart() {
    this.submitBtnTarget.disabled = true
    this.submitBtnTarget.innerHTML = `
      <svg class="animate-spin h-4 w-4 inline-block mr-1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
      </svg>
      Uploading…`
  }

  onSubmitEnd() {
    this.submitBtnTarget.innerHTML = "Upload"
    this.fileInputTarget.value = ""
    this.toggle()
  }
}
