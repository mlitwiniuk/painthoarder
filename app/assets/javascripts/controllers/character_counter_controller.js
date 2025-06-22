import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["count"];
  static values = { max: Number };

  connect() {
    this.updateCount();
    this.setupTextarea();
    console.log("CharacterCounterController connected");
  }

  setupTextarea() {
    // Find the textarea that this counter is associated with
    // Look for textarea in the same form-control or nearby
    const formControl = this.element.closest(".form-control");
    this.textarea =
      formControl?.querySelector("textarea") ||
      document.querySelector('textarea[maxlength="' + this.maxValue + '"]');

    if (this.textarea) {
      this.textarea.addEventListener("input", this.updateCount.bind(this));
      this.textarea.addEventListener("paste", () => {
        // Small delay to allow paste to complete
        setTimeout(() => this.updateCount(), 10);
      });
    }
  }

  updateCount() {
    if (!this.textarea) return;

    const currentLength = this.textarea.value.length;
    this.countTarget.textContent = currentLength;

    // Update styling based on character count
    this.updateStyling(currentLength);
  }

  updateStyling(currentLength) {
    const percentage = (currentLength / this.maxValue) * 100;

    // Remove existing classes
    this.element.classList.remove("text-warning", "text-error");

    if (percentage >= 100) {
      this.element.classList.add("text-error");
    } else if (percentage >= 80) {
      this.element.classList.add("text-warning");
    }

    // Optional: Update the counter color
    this.countTarget.classList.remove("text-warning", "text-error");

    if (percentage >= 100) {
      this.countTarget.classList.add("text-error");
    } else if (percentage >= 80) {
      this.countTarget.classList.add("text-warning");
    }
  }

  disconnect() {
    if (this.textarea) {
      this.textarea.removeEventListener("input", this.updateCount.bind(this));
    }
  }
}
