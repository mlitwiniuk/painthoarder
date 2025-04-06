import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    // Opening modal animations - if using DaisyUI which already has classes for this
    if (this.element.classList.contains('modal')) {
      this.element.classList.add('modal-open');
      
      // Add event listener for ESC key
      document.addEventListener("keydown", this.handleEscKey);
    }
  }
  
  disconnect() {
    // Remove the event listener when controller disconnects
    document.removeEventListener("keydown", this.handleEscKey);
  }

  handleEscKey = (event) => {
    if (event.key === "Escape") {
      this.close();
    }
  }

  // Used for opening a modal from a button/link that isn't using turbo frames
  open(event) {
    const modalId = event.params.id || event.target.dataset.modalId;
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.classList.add('modal-open');
    }
  }

  // Close the modal when backdrop clicked
  closeBackground(event) {
    // Only close if clicking the backdrop (the element with modal class)
    // and not when clicking on any of its children
    if (event.target === this.element) {
      this.close();
    }
  }

  // Close with keyboard shortcuts
  closeWithKeyboard(event) {
    if (event.key === "Escape") {
      this.close();
    }
  }

  // Handle form submission completion
  handleSubmit(event) {
    // Only close the modal on successful submissions (no validation errors)
    // Check if the response is a success (200-299 status code)
    if (event.detail.success) {
      this.close();
    }
  }

  // General close method
  close() {
    if (this.element.classList.contains('modal')) {
      this.element.classList.remove('modal-open');
    }
    
    // If this is inside a turbo frame, we want to empty it after closing
    const frame = this.element.closest('turbo-frame');
    if (frame) {
      // Short delay to allow for animations
      setTimeout(() => {
        frame.innerHTML = '';
      }, 300);
    }
  }
}
