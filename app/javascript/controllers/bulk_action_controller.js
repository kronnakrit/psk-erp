import { Controller } from "@hotwired/stimulus"

// Manages bulk row selection on the Orders index page.
// Reveals the bulk action bar when at least one row checkbox is checked,
// handles Select All, and injects selected IDs into the submit forms.
export default class extends Controller {
  connect () {
    this.updateBar()

    // Observe individual row checkboxes
    this.element.querySelectorAll(".order_checkbox").forEach(cb => {
      cb.addEventListener("change", () => this.updateBar())
    })

    // Observe the Select-All header checkbox
    const selectAll = this.element.querySelector("#select_all_checkbox")
    if (selectAll) {
      selectAll.addEventListener("change", () => this.toggleAll(selectAll.checked))
    }

    // Intercept bulk-status form to inject ids[] + status
    const statusForm = document.getElementById("bulk_status_form")
    if (statusForm) {
      statusForm.addEventListener("submit", (e) => this.prepareStatusForm(e, statusForm))
    }

    // Intercept combine-bills form to inject ids[]
    const combineBillsForm = document.getElementById("combine_bills_form")
    if (combineBillsForm) {
      combineBillsForm.addEventListener("submit", (e) => this.prepareCombineBillsForm(e, combineBillsForm))
    }

    // Intercept export-excel form to inject ids[]
    const exportExcelForm = document.getElementById("export_excel_form")
    if (exportExcelForm) {
      exportExcelForm.addEventListener("submit", (e) => this.prepareExportExcelForm(e, exportExcelForm))
    }
  }

  // Show/hide the bar and update counter
  updateBar () {
    const checked = this.element.querySelectorAll(".order_checkbox:checked")
    const bar      = document.getElementById("bulk_action_bar")
    const countEl  = document.getElementById("selected_count")

    if (bar) bar.classList.toggle("hidden", checked.length === 0)
    if (countEl) countEl.textContent = checked.length
  }

  // Toggle all row checkboxes in step with the header checkbox
  toggleAll (checked) {
    this.element.querySelectorAll(".order_checkbox").forEach(cb => {
      cb.checked = checked
    })
    this.updateBar()
  }

  // Inject ids[] and status hidden inputs before the bulk status form submits
  prepareStatusForm (_event, form) {
    this.removeInjected(form)

    this.selectedIds().forEach(id => {
      form.appendChild(this.hiddenInput("ids[]", id))
    })

    const statusSelect = document.getElementById("bulk_status_select")
    if (statusSelect) {
      form.appendChild(this.hiddenInput("status", statusSelect.value))
    }
  }

  // Inject ids[] hidden inputs before the combine bills form submits
  prepareCombineBillsForm (_event, form) {
    this.removeInjected(form)

    this.selectedIds().forEach(id => {
      form.appendChild(this.hiddenInput("ids[]", id))
    })
  }

  // Inject ids[] hidden inputs before the export excel form submits
  prepareExportExcelForm (_event, form) {
    this.removeInjected(form)

    this.selectedIds().forEach(id => {
      form.appendChild(this.hiddenInput("ids[]", id))
    })
  }

  // --- helpers ---

  selectedIds () {
    return Array.from(this.element.querySelectorAll(".order_checkbox:checked")).map(cb => cb.value)
  }

  removeInjected (form) {
    form.querySelectorAll("input[data-injected]").forEach(el => el.remove())
  }

  hiddenInput (name, value) {
    const input = document.createElement("input")
    input.type  = "hidden"
    input.name  = name
    input.value = value
    input.dataset.injected = "true"
    return input
  }
}
