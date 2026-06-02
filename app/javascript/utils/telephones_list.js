// Document-level handlers for dynamic customer telephone rows.
// Delegation avoids Turbo frame/cache re-init issues with inline scripts.
document.addEventListener("click", (event) => {
  const addButton = event.target.closest("[data-telephones-list-add]")
  if (addButton) {
    event.preventDefault()

    const root = addButton.closest("[data-telephones-list]")
    const list = root?.querySelector("[data-telephones-list-target='list']")
    if (!list) return

    const rows = list.querySelectorAll(".js-telephone-row")
    const source = rows[rows.length - 1]
    if (!source) return

    const row = source.cloneNode(true)
    const input = row.querySelector("input[type='text']")
    if (input) {
      input.value = ""
      input.removeAttribute("id")
    }

    list.appendChild(row)
    input?.focus()
    return
  }

  const removeButton = event.target.closest("[data-telephones-list-remove]")
  if (!removeButton) return

  event.preventDefault()

  const root = removeButton.closest("[data-telephones-list]")
  const list = root?.querySelector("[data-telephones-list-target='list']")
  const row = removeButton.closest(".js-telephone-row")
  if (!list || !row) return

  const rows = list.querySelectorAll(".js-telephone-row")
  if (rows.length <= 1) {
    const onlyInput = row.querySelector("input[type='text']")
    if (onlyInput) onlyInput.value = ""
    return
  }

  row.remove()
})
