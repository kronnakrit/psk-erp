import { Controller } from "@hotwired/stimulus"

// Renders the dashboard revenue bar chart (Chart.js loaded globally in layout).
export default class extends Controller {
  static targets = ["canvas"]
  static values = { data: Object }

  connect() {
    this.chart = null
    this.scheduleRender(0)
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  scheduleRender(attempt) {
    if (typeof Chart !== "undefined") {
      this.renderChart()
      return
    }
    if (attempt < 30) {
      requestAnimationFrame(() => this.scheduleRender(attempt + 1))
    }
  }

  renderChart() {
    if (!this.hasCanvasTarget || this.chart) return

    const chartData = this.dataValue || {}
    const labels = Object.keys(chartData)
    const values = Object.values(chartData)

    this.chart = new Chart(this.canvasTarget, {
      type: "bar",
      data: {
        labels,
        datasets: [{
          label: "Revenue (฿)",
          data: values,
          backgroundColor: "#2563eb",
          borderRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          y: {
            ticks: {
              callback: (value) => `฿${Number(value).toLocaleString()}`
            }
          }
        }
      }
    })
  }
}
