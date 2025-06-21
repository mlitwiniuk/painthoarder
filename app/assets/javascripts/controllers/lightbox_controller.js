import { Controller } from "@hotwired/stimulus";

// Lightbox controller: builds its own modal dynamically and uses
// Stimulus targets/actions only – no manual addEventListener calls.
export default class extends Controller {
  static targets = ["thumbnail", "modal", "image"];

  connect() {
    // Key handler bound once per controller instance
    this._handleKey = this.handleKey.bind(this);
    // Build the modal the first time the controller appears
    if (!this.hasModalTarget) {
      this.buildModal();
    }
  }

  // ------------------------------------------------------------------
  // Modal creation
  // ------------------------------------------------------------------
  buildModal() {
    const wrapper = document.createElement("div");
    wrapper.className = "modal";
    wrapper.dataset.lightboxTarget = "modal";

    wrapper.innerHTML = `
      <div class="modal-box p-0 relative max-w-5xl">
        <button class="btn btn-circle absolute top-2 right-2" data-action="click->lightbox#close">✕</button>
        <button class="btn btn-circle absolute left-2 top-1/2 z-10" data-action="click->lightbox#prev">❮</button>
        <button class="btn btn-circle absolute right-2 top-1/2 z-10" data-action="click->lightbox#next">❯</button>
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
  }

  next() {
    this.index = (this.index + 1) % this.thumbnailTargets.length;
    this.showCurrent();
  }

  prev() {
    this.index = (this.index - 1 + this.thumbnailTargets.length) % this.thumbnailTargets.length;
    this.showCurrent();
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

