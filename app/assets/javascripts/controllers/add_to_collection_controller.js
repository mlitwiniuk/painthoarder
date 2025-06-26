import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button", "loading"];

  connect() {
    // Add smooth transitions to all buttons
    this.buttonTargets.forEach((button) => {
      button.classList.add("transition-all", "duration-200");
    });
  }

  addToCollection(event) {
    const button = event.currentTarget;
    const form = button.closest("form");

    if (!form) return;

    // Show loading state
    this.showLoading(button);

    // Add visual feedback
    button.classList.add("loading", "loading-spinner");
    button.disabled = true;

    // Submit the form
    form.addEventListener(
      "turbo:submit-end",
      (e) => {
        this.handleSubmitEnd(e, button);
      },
      { once: true },
    );

    // Handle submit errors
    form.addEventListener(
      "turbo:submit-error",
      (e) => {
        this.handleSubmitError(e, button);
      },
      { once: true },
    );
  }

  handleSubmitEnd(event, button) {
    // Remove loading state
    this.hideLoading(button);

    if (event.detail.success !== false) {
      // Success - show brief success state
      this.showSuccess(button);

      // Add haptic feedback
      this.addHapticFeedback();

      // Redirect to the new user paint after a brief delay
      setTimeout(() => {
        // The response should contain the redirect URL
        if (event.detail.response && event.detail.response.redirected) {
          window.location.href = event.detail.response.url;
        } else {
          // Fallback: reload the page to show the updated state
          window.location.reload();
        }
      }, 1000);
    } else {
      // Handle validation errors
      this.handleSubmitError(event, button);
    }
  }

  handleSubmitError(event, button) {
    // Remove loading state
    this.hideLoading(button);

    // Show error state
    button.classList.remove("loading", "loading-spinner");
    button.classList.add("btn-error");
    button.disabled = false;

    // Reset error state after a delay
    setTimeout(() => {
      button.classList.remove("btn-error");
    }, 2000);

    // Optionally show error message
    console.error("Add to collection failed:", event.detail);
  }

  showLoading(button) {
    // Disable all action buttons
    this.buttonTargets.forEach((btn) => {
      if (btn !== button) {
        btn.disabled = true;
        btn.classList.add("opacity-50");
      }
    });

    // Show loading overlay if it exists
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("hidden");
    }
  }

  hideLoading(button) {
    // Re-enable all action buttons
    this.buttonTargets.forEach((btn) => {
      btn.disabled = false;
      btn.classList.remove("opacity-50", "loading", "loading-spinner");
    });

    // Hide loading overlay
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden");
    }
  }

  showSuccess(button) {
    button.classList.remove("loading", "loading-spinner");
    button.classList.add("btn-success");

    // Add success icon temporarily
    const originalContent = button.innerHTML;
    button.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 sm:h-3.5 sm:w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
      </svg>
      <span class="hidden sm:inline ml-1.5 text-xs font-medium">Added!</span>
    `;

    // Don't restore original content since we're redirecting
  }

  // Add haptic feedback on mobile devices
  addHapticFeedback() {
    if ("vibrate" in navigator) {
      navigator.vibrate(50); // Short vibration
    }
  }

  // Handle keyboard shortcuts
  handleKeydown(event) {
    // Add keyboard shortcuts for power users
    if (event.metaKey || event.ctrlKey) {
      switch (event.key) {
        case "1":
          event.preventDefault();
          this.triggerAddToCollection("owned");
          break;
        case "2":
          event.preventDefault();
          this.triggerAddToCollection("wishlist");
          break;
        case "3":
          event.preventDefault();
          this.triggerAddToCollection("avoid");
          break;
      }
    }
  }

  triggerAddToCollection(status) {
    const targetButton = this.buttonTargets.find((btn) => {
      const form = btn.closest("form");
      const statusInput = form?.querySelector('input[name*="status"]');
      return statusInput?.value === status;
    });

    if (targetButton) {
      this.addHapticFeedback();
      targetButton.click();
    }
  }

  disconnect() {
    // Clean up any ongoing timeouts or intervals
    this.buttonTargets.forEach((btn) => {
      btn.disabled = false;
      btn.classList.remove("opacity-50", "loading", "loading-spinner");
    });
  }
}
