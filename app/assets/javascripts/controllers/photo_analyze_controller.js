import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "form",
    "submitButton",
    "progressContainer",
    "progressBar",
    "progressText",
    "fileInput",
    "uploadArea",
  ];

  connect() {
    this.formTarget.addEventListener(
      "turbo:submit-start",
      this.showProgress.bind(this),
    );
    this.formTarget.addEventListener(
      "turbo:submit-end",
      this.hideProgress.bind(this),
    );
  }

  disconnect() {
    this.formTarget.removeEventListener(
      "turbo:submit-start",
      this.showProgress.bind(this),
    );
    this.formTarget.removeEventListener(
      "turbo:submit-end",
      this.hideProgress.bind(this),
    );
  }

  fileSelected(event) {
    const file = event.target.files[0];
    if (file) {
      // Check file size (5MB limit)
      const maxSize = 4 * 1024 * 1024; // 4MB in bytes
      const fileSize = file.size;
      const fileSizeMB = (fileSize / 1024 / 1024).toFixed(2);

      // Update the upload area to show file name
      const uploadCard = event.target.closest(".card");
      if (uploadCard) {
        if (fileSize > maxSize) {
          // File too large
          uploadCard.classList.remove("border-primary", "bg-primary/5");
          uploadCard.classList.add("border-error", "bg-error/5");
          const labelDiv = uploadCard.querySelector(".flex-col");
          if (labelDiv) {
            labelDiv.innerHTML = `
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-12 h-12 text-error">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
              </svg>
              <div class="mt-2">
                <p class="text-lg font-medium text-error">File too large!</p>
                <p class="text-sm text-base-content/60">${file.name}</p>
                <p class="text-sm text-error">${fileSizeMB} MB exceeds 4MB limit</p>
              </div>
            `;
          }
          // Disable submit button
          if (this.hasSubmitButtonTarget) {
            this.submitButtonTarget.disabled = true;
            this.submitButtonTarget.classList.add("btn-disabled");
          }
          // Clear the file input
          event.target.value = "";
        } else {
          // File size OK - show image preview
          uploadCard.classList.remove("border-error", "bg-error/5");
          uploadCard.classList.add("border-primary", "bg-primary/5");
          
          // Create a FileReader to display the image
          const reader = new FileReader();
          reader.onload = (e) => {
            const labelDiv = uploadCard.querySelector(".flex-col");
            if (labelDiv) {
              labelDiv.innerHTML = `
                <div class="relative">
                  <img src="${e.target.result}" 
                       alt="Selected photo preview" 
                       class="max-h-48 rounded-lg shadow-lg object-contain mx-auto" />
                  <div class="absolute top-2 right-2 badge badge-primary">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4 mr-1">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    Ready
                  </div>
                </div>
                <div class="mt-3 text-center">
                  <p class="text-sm font-medium text-base-content">${file.name}</p>
                  <p class="text-xs text-base-content/60">${fileSizeMB} MB</p>
                </div>
              `;
            }
          };
          reader.readAsDataURL(file);
          
          // Enable submit button
          if (this.hasSubmitButtonTarget) {
            this.submitButtonTarget.disabled = false;
            this.submitButtonTarget.classList.remove("btn-disabled");
          }
        }
      }
    }
  }

  showProgress(event) {
    // Only show progress for the photo analysis form
    if (
      !event.detail.formSubmission.formElement.querySelector(
        'input[type="file"]',
      )
    ) {
      return;
    }

    // Hide submit button and show progress
    this.submitButtonTarget.classList.add("hidden");
    this.progressContainerTarget.classList.remove("hidden");

    // Start progress animation
    this.animateProgress();
  }

  hideProgress() {
    // Show submit button and hide progress
    this.submitButtonTarget.classList.remove("hidden");
    this.progressContainerTarget.classList.add("hidden");

    // Reset progress
    this.progressBarTarget.style.width = "0%";

    // Clear any running animation
    if (this.progressInterval) {
      clearInterval(this.progressInterval);
    }
  }

  animateProgress() {
    let progress = 0;
    const steps = [
      { percent: 20, text: "Uploading photo..." },
      { percent: 40, text: "Analyzing image..." },
      { percent: 60, text: "Identifying paints..." },
      { percent: 80, text: "Searching database..." },
      { percent: 95, text: "Almost done..." },
    ];

    let currentStep = 0;

    this.progressInterval = setInterval(() => {
      if (currentStep < steps.length) {
        const step = steps[currentStep];
        progress = step.percent;
        this.progressBarTarget.style.width = `${progress}%`;
        this.progressTextTarget.textContent = step.text;
        currentStep++;
      } else {
        // Keep at 95% until response comes back
        this.progressBarTarget.style.width = "95%";
      }
    }, 1500); // Update every 1.5 seconds
  }
}
