import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "previewContainer",
    "colorSwatch",
    "colorCode",
    "paintName",
  ];

  connect() {
    this.hidePreview();

    // Listen for paint selection from the cascading select controller
    this.element.addEventListener(
      "paint-selected",
      this.handlePaintSelection.bind(this),
    );

    // Check if there's already a selected paint on load
    this.checkInitialSelection();
  }

  disconnect() {
    this.element.removeEventListener(
      "paint-selected",
      this.handlePaintSelection.bind(this),
    );
  }

  checkInitialSelection() {
    const paintSelect = document.getElementById("user_paint_paint_id");
    if (paintSelect && paintSelect.value) {
      this.updatePreview({ target: paintSelect });
    }
  }

  updatePreview(event) {
    const selectedOption = event.target.options[event.target.selectedIndex];

    if (
      selectedOption &&
      selectedOption.value &&
      selectedOption.dataset.color
    ) {
      const color = selectedOption.dataset.color;
      const paintText = selectedOption.textContent.trim();

      this.showPreview(color, paintText);
    } else {
      this.hidePreview();
    }
  }

  showPreview(color, paintText) {
    // Update color swatch
    if (this.hasColorSwatchTarget) {
      this.colorSwatchTarget.style.backgroundColor = color;
    }

    // Update color code
    if (this.hasColorCodeTarget) {
      this.colorCodeTarget.textContent = color.toUpperCase();
    }

    // Update paint name if target exists
    if (this.hasPaintNameTarget) {
      this.paintNameTarget.textContent = paintText;
    }

    // Show the preview container
    if (this.hasPreviewContainerTarget) {
      this.previewContainerTarget.classList.remove("hidden");
      this.previewContainerTarget.classList.add("animate-fade-in");
    }
  }

  hidePreview() {
    if (this.hasPreviewContainerTarget) {
      this.previewContainerTarget.classList.add("hidden");
      this.previewContainerTarget.classList.remove("animate-fade-in");
    }

    // Reset swatch color
    if (this.hasColorSwatchTarget) {
      this.colorSwatchTarget.style.backgroundColor = "#f3f4f6";
    }

    // Clear text content
    if (this.hasColorCodeTarget) {
      this.colorCodeTarget.textContent = "";
    }

    if (this.hasPaintNameTarget) {
      this.paintNameTarget.textContent = "Paint Preview";
    }
  }

  handlePaintSelection(event) {
    const paintId = event.detail.paintId;

    // Find the paint option in the select element
    const paintSelect = document.getElementById("user_paint_paint_id");
    if (paintSelect) {
      const selectedOption = paintSelect.querySelector(
        `option[value="${paintId}"]`,
      );
      if (selectedOption && selectedOption.dataset.color) {
        const color = selectedOption.dataset.color;
        const paintText = selectedOption.textContent.trim();
        this.showPreview(color, paintText);
        return;
      }
    }

    // Fallback: fetch paint details if not found in DOM
    fetch(`/api/paints/${paintId}`)
      .then((response) => response.json())
      .then((data) => {
        if (data.color) {
          const paintText = `${data.name} (${data.code})`;
          this.showPreview(data.color, paintText);
        }
      })
      .catch((error) => {
        console.error("Error fetching paint details:", error);
        this.hidePreview();
      });
  }
}
