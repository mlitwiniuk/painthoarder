import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["previewContainer", "colorSwatch", "colorCode"]
  
  connect() {
    this.previewContainerTarget.classList.add("hidden")
    
    // Listen for paint selection from the cascading select controller
    this.element.addEventListener('paint-selected', this.handlePaintSelection.bind(this))
  }
  
  disconnect() {
    this.element.removeEventListener('paint-selected', this.handlePaintSelection.bind(this))
  }
  
  updatePreview(event) {
    const selectedOption = event.target.options[event.target.selectedIndex]
    
    if (selectedOption && selectedOption.dataset.color) {
      const color = selectedOption.dataset.color
      this.colorSwatchTarget.style.backgroundColor = color
      this.colorCodeTarget.textContent = color
      this.previewContainerTarget.classList.remove("hidden")
    } else {
      this.previewContainerTarget.classList.add("hidden")
    }
  }
  
  handlePaintSelection(event) {
    const paintId = event.detail.paintId
    
    // Get color information by fetching paint details
    fetch(`/api/paints/${paintId}`)
      .then(response => response.json())
      .then(data => {
        if (data.color) {
          this.colorSwatchTarget.style.backgroundColor = data.color
          this.colorCodeTarget.textContent = data.color
          this.previewContainerTarget.classList.remove("hidden")
        }
      })
      .catch(error => {
        console.error("Error fetching paint details:", error)
      })
  }
}
