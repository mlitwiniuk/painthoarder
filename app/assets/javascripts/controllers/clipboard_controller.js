import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { text: String };

  connect() {
    // Set up initial styles for toast animations
    const style = document.createElement("style");
    style.textContent = `
      .alert.fixed {
        transform: translateX(100%);
        opacity: 0;
        transition: transform 0.3s ease-out, opacity 0.3s ease-out;
      }
    `;
    if (!document.querySelector("#clipboard-toast-styles")) {
      style.id = "clipboard-toast-styles";
      document.head.appendChild(style);
    }
    console.log("Connected clipboard controller");
  }

  async copy(event) {
    console.log("Copying text:", this.textValue);
    event.preventDefault();

    try {
      // Try modern clipboard API first
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(this.textValue);
        this.showSuccess();
      } else {
        // Fallback for older browsers or non-secure contexts
        this.fallbackCopy();
      }
    } catch (error) {
      console.error("Failed to copy text:", error);
      this.showError();
    }
  }

  fallbackCopy() {
    // Create a temporary textarea
    const textArea = document.createElement("textarea");
    textArea.value = this.textValue;
    textArea.style.position = "fixed";
    textArea.style.left = "-999999px";
    textArea.style.top = "-999999px";
    document.body.appendChild(textArea);

    textArea.focus();
    textArea.select();

    try {
      const successful = document.execCommand("copy");
      if (successful) {
        this.showSuccess();
      } else {
        this.showError();
      }
    } catch (error) {
      console.error("Fallback copy failed:", error);
      this.showError();
    } finally {
      document.body.removeChild(textArea);
    }
  }

  showSuccess() {
    const button = this.element;
    const originalText = button.innerHTML;

    // Change button to success state
    button.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
      </svg>
      Copied!
    `;
    button.classList.remove("btn-primary");
    button.classList.add("btn-success");

    // Reset after 2 seconds
    setTimeout(() => {
      button.innerHTML = originalText;
      button.classList.remove("btn-success");
      button.classList.add("btn-primary");
    }, 2000);

    // Show toast notification if available
    this.showToast("Link copied to clipboard!", "success");
  }

  showError() {
    const button = this.element;
    const originalText = button.innerHTML;

    // Change button to error state
    button.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
      </svg>
      Failed
    `;
    button.classList.remove("btn-primary");
    button.classList.add("btn-error");

    // Reset after 2 seconds
    setTimeout(() => {
      button.innerHTML = originalText;
      button.classList.remove("btn-error");
      button.classList.add("btn-primary");
    }, 2000);

    // Show toast notification if available
    this.showToast("Failed to copy link. Please try again.", "error");
  }

  showToast(message, type) {
    // Create toast element
    const toast = document.createElement("div");
    toast.className = `alert alert-${type} fixed top-4 right-4 z-50 max-w-sm shadow-lg`;
    toast.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
        ${
          type === "success"
            ? '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />'
            : '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />'
        }
      </svg>
      <span>${message}</span>
    `;

    // Add to DOM with animation
    document.body.appendChild(toast);

    // Trigger slide-in animation
    requestAnimationFrame(() => {
      toast.style.transform = "translateX(0)";
      toast.style.opacity = "1";
    });

    // Remove after 3 seconds
    setTimeout(() => {
      toast.style.transform = "translateX(100%)";
      toast.style.opacity = "0";
      setTimeout(() => {
        if (toast.parentNode) {
          document.body.removeChild(toast);
        }
      }, 300);
    }, 3000);
  }
}
