import { Controller } from "@hotwired/stimulus"

// POSTs date range to a report endpoint and triggers a file download.
export default class extends Controller {
  static targets = ["startDate", "endDate"]

  download(event) {
    event.preventDefault()

    const url = event.params.url
    if (!url) return

    const form = document.createElement("form")
    form.method = "POST"
    form.action = url

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrf = document.createElement("input")
      csrf.type = "hidden"
      csrf.name = "authenticity_token"
      csrf.value = csrfToken
      form.appendChild(csrf)
    }

    [
      ["start_date", this.startDateTarget.value],
      ["end_date", this.endDateTarget.value]
    ].forEach(([name, value]) => {
      const field = document.createElement("input")
      field.type = "hidden"
      field.name = name
      field.value = value
      form.appendChild(field)
    })

    document.body.appendChild(form)
    form.submit()
    document.body.removeChild(form)
  }
}
