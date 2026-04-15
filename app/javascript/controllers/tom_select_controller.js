import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

// Wraps any <select> with Tom Select for searchable typeahead behaviour.
// Usage:
//   <%= f.select :foo, options, {}, data: { controller: "tom-select" } %>
//
// Options (via data-tom-select-* attributes):
//   data-tom-select-placeholder-value  Override the default placeholder text.
//   data-tom-select-create-value       "true" to allow typing new options (default: false).
export default class extends Controller {
  static values = {
    placeholder: { type: String, default: "" },
    create: { type: Boolean, default: false },
  }

  connect () {
    // Avoid double-initialisation on Turbo cache restore
    if (this.element.tomselect) return

    const isMultiple = this.element.multiple

    const options = {
      create: this.createValue,
      placeholder: this.placeholderValue || this.#defaultPlaceholder(),
      allowEmptyOption: !isMultiple,
      closeAfterSelect: !isMultiple,
      // Keep option order from server (don't re-sort alphabetically)
      sortField: { field: "$order", direction: "asc" },
      // Render highlighted match in options
      render: {
        option: (data, escape) => `<div class="option">${escape(data.text)}</div>`,
        item:   (data, escape) => `<div>${escape(data.text)}</div>`,
      },
    }

    this.ts = new TomSelect(this.element, options)
  }

  disconnect () {
    if (this.ts) {
      this.ts.destroy()
      this.ts = null
    }
  }

  // Pull placeholder from the first blank <option> if present
  #defaultPlaceholder () {
    const blank = this.element.querySelector("option[value='']")
    return blank ? blank.textContent.trim() : ""
  }
}
