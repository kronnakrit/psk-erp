import { Controller } from "@hotwired/stimulus"

// Lot-selection modal for manual stock deposit/withdraw on stocks/show.
export default class extends Controller {
  static targets = [
    "modal",
    "form",
    "title",
    "subtitle",
    "lotSelect",
    "amountField",
    "reasonField",
    "submitBtn",
    "noLotsMessage",
    "fieldsPanel"
  ]

  static values = {
    depositUrl: String,
    withdrawUrl: String,
    depositTitle: String,
    withdrawTitle: String,
    confirmDeposit: String,
    confirmWithdraw: String,
    noEligibleLots: String,
    submitDepositClass: String,
    submitWithdrawClass: String
  }

  openDeposit (event) {
    event.preventDefault()
    this._open("deposit")
  }

  openWithdraw (event) {
    event.preventDefault()
    this._open("withdraw")
  }

  close () {
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  closeOnBackdrop (event) {
    if (event.target === this.modalTarget) this.close()
  }

  closeOnEscape (event) {
    if (event.key === "Escape" && !this.modalTarget.classList.contains("hidden")) {
      event.preventDefault()
      this.close()
    }
  }

  stopPropagation (event) {
    event.stopPropagation()
  }

  _open (mode) {
    this._mode = mode
    const isDeposit = mode === "deposit"

    this.titleTarget.textContent = isDeposit ? this.depositTitleValue : this.withdrawTitleValue
    if (this.hasSubtitleTarget) {
      this.subtitleTarget.textContent = isDeposit
        ? this.confirmDepositValue
        : this.confirmWithdrawValue
    }
    this.formTarget.action = this.depositUrlValue
    this.submitBtnTarget.textContent = isDeposit ? this.confirmDepositValue : this.confirmWithdrawValue
    this.submitBtnTarget.formAction = isDeposit ? this.depositUrlValue : this.withdrawUrlValue
    this.submitBtnTarget.className = isDeposit
      ? this.submitDepositClassValue
      : this.submitWithdrawClassValue

    const eligible = this._filterLotOptions(isDeposit)
    if (eligible.length === 0) {
      this.fieldsPanelTarget.classList.add("hidden")
      this.noLotsMessageTarget.classList.remove("hidden")
      this.noLotsMessageTarget.textContent = this.noEligibleLotsValue
      this.submitBtnTarget.disabled = true
    } else {
      this.fieldsPanelTarget.classList.remove("hidden")
      this.noLotsMessageTarget.classList.add("hidden")
      this.submitBtnTarget.disabled = false
      this.lotSelectTarget.value = eligible[0].value
    }

    this.amountFieldTarget.value = ""
    this.reasonFieldTarget.value = ""
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")

    window.requestAnimationFrame(() => {
      this.amountFieldTarget.focus()
    })
  }

  _filterLotOptions (isDeposit) {
    const options = Array.from(this.lotSelectTarget.options)

    options.forEach((option) => {
      if (!option.value) {
        option.hidden = true
        option.disabled = true
        return
      }

      const remaining = parseFloat(option.dataset.remaining || "0")
      const eligible = isDeposit || remaining > 0
      option.hidden = !eligible
      option.disabled = !eligible
    })

    return options.filter((o) => !o.hidden && o.value)
  }
}
