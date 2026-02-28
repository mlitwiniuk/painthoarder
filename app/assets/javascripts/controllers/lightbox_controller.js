import { Controller } from "@hotwired/stimulus";

// Lightbox controller: uses a single shared modal rendered once in the
// layout via shared/_lightbox_modal. Multiple controller instances on
// the same page all reference the same modal element by ID.
export default class extends Controller {
  static targets = ["thumbnail"];

  connect() {
    this._handleKey = this.handleKey.bind(this);
    this.modal = document.getElementById("lightbox-modal");
    this.img = document.getElementById("lightbox-image");
    this.prevBtn = document.getElementById("lightbox-prev");
    this.nextBtn = document.getElementById("lightbox-next");
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
    this.modal.classList.remove("modal-open");
  }

  // ------------------------------------------------------------------
  // Private helpers
  // ------------------------------------------------------------------
  showCurrent() {
    if (!this.modal.classList.contains("modal-open")) {
      window.addEventListener("keydown", this._handleKey);
    }

    if (this.img) {
      const url = this.thumbnailTargets[this.index].dataset.fullUrl;
      this.img.src = url;
      this.updateNavigationButtons();
    }

    this.modal.classList.add("modal-open");
  }

  updateNavigationButtons() {
    if (this.prevBtn) {
      this.prevBtn.classList.toggle("hidden", this.index === 0);
      this.prevBtn.onclick = () => this.prev();
    }

    if (this.nextBtn) {
      this.nextBtn.classList.toggle("hidden", this.index === this.thumbnailTargets.length - 1);
      this.nextBtn.onclick = () => this.next();
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
