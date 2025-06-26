import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["submitButton"];

  connect() {
    // Add loading state handling
    this.element.addEventListener("turbo:submit-start", this.handleSubmitStart.bind(this));
    this.element.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this));
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-start", this.handleSubmitStart.bind(this));
    this.element.removeEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this));
  }

  handleSubmitStart() {
    // Disable submit button and show loading state
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true;
      this.submitButtonTarget.classList.add("loading");

      // Store original text
      this.originalText = this.submitButtonTarget.textContent;
      this.submitButtonTarget.textContent = "Saving...";
    }

    // Disable all form inputs to prevent changes during submission
    this.disableFormInputs();
  }

  handleSubmitEnd(event) {
    // Re-enable submit button
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false;
      this.submitButtonTarget.classList.remove("loading");

      if (this.originalText) {
        this.submitButtonTarget.textContent = this.originalText;
      }
    }

    // Re-enable form inputs
    this.enableFormInputs();

    // Check if submission was successful
    const response = event.detail.fetchResponse;
    if (response && response.ok) {
      // Successful submission
      event.detail.success = true;
    } else {
      // Failed submission
      event.detail.success = false;
    }
  }

  disableFormInputs() {
    const inputs = this.element.querySelectorAll("input, select, textarea, button");
    inputs.forEach(input => {
      if (!input.disabled) {
        input.disabled = true;
        input.dataset.wasEnabled = "true";
      }
    });
  }

  enableFormInputs() {
    const inputs = this.element.querySelectorAll("input, select, textarea, button");
    inputs.forEach(input => {
      if (input.dataset.wasEnabled === "true") {
        input.disabled = false;
        delete input.dataset.wasEnabled;
      }
    });
  }
}
