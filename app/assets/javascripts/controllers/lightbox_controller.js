import { Controller } from "@hotwired/stimulus";

// Lightbox controller: builds its own modal dynamically and uses
// Stimulus targets/actions only – no manual addEventListener calls.
export default class extends Controller {
  static targets = ["thumbnail", "modal", "image", "prevButton", "nextButton"];

  connect() {
    // Key handler bound once per controller instance
    this._handleKey = this.handleKey.bind(this);
    // Build the modal the first time the controller appears
    if (!this.hasModalTarget) {
      this.buildModal();
    }
    console.log("Lightbox connected");
  }

  // ------------------------------------------------------------------
  // Modal creation
  // ------------------------------------------------------------------
  buildModal() {
    const wrapper = document.createElement("div");
    wrapper.className = "modal";
    wrapper.dataset.lightboxTarget = "modal";

    wrapper.innerHTML = `
      <div class="modal-box p-0 relative max-w-7xl">
        <button class="btn btn-circle absolute top-2 right-2" data-action="click->lightbox#close">✕</button>
        <button class="btn btn-circle absolute left-2 top-1/2 z-10" data-action="click->lightbox#prev" data-lightbox-target="prevButton">❮</button>
        <button class="btn btn-circle absolute right-2 top-1/2 z-10" data-action="click->lightbox#next" data-lightbox-target="nextButton">❯</button>
        <img data-lightbox-target="image" class="w-full h-auto object-contain" alt="Project image" />
      </div>`;

    // Append inside the same element so Stimulus keeps context
    this.element.appendChild(wrapper);
  }

  // ------------------------------------------------------------------
  // Public actions
  // ------------------------------------------------------------------
  open(event) {
    event.preventDefault();
    this.index = this.thumbnailTargets.indexOf(event.currentTarget);
    this.showCurrent();
    console.log("Lightbox opened");
  }

  next() {
    if (this.index < this.thumbnailTargets.length - 1) {
      this.index++;
      this.showCurrent();
    }
  }

  prev() {
    if (this.index > 0) {
      this.index--;
      this.showCurrent();
    }
  }

  close() {
    window.removeEventListener("keydown", this._handleKey);
    this.modalTarget.classList.remove("modal-open");
  }

  // ------------------------------------------------------------------
  // Private helpers
  // ------------------------------------------------------------------
  showCurrent() {
    // Add key listener once when modal is shown
    if (!this.modalTarget.classList.contains("modal-open")) {
      window.addEventListener("keydown", this._handleKey);
    }
    const url = this.thumbnailTargets[this.index].dataset.fullUrl;
    this.imageTarget.src = url;
    this.modalTarget.classList.add("modal-open");
    
    // Update button visibility
    this.updateNavigationButtons();
  }
  
  updateNavigationButtons() {
    // Hide/show prev button
    if (this.hasPrevButtonTarget) {
      if (this.index === 0) {
        this.prevButtonTarget.classList.add("hidden");
      } else {
        this.prevButtonTarget.classList.remove("hidden");
      }
    }
    
    // Hide/show next button
    if (this.hasNextButtonTarget) {
      if (this.index === this.thumbnailTargets.length - 1) {
        this.nextButtonTarget.classList.add("hidden");
      } else {
        this.nextButtonTarget.classList.remove("hidden");
      }
    }
  }

  // ------------------------------------------------------------------
  // Keyboard handler
  // ------------------------------------------------------------------
  handleKey(event) {
    switch (event.key) {
      case "ArrowRight":
        this.next();
        break;
      case "ArrowLeft":
        this.prev();
        break;
      case "Escape":
        this.close();
        break;
    }
  }
}
