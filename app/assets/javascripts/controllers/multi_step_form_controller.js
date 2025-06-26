import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "step",
    "nextButton",
    "prevButton",
    "submitButton",
    "backButton",
    "stepTitle",
    "currentStepNumber",
    "progressPercent",
    "progressBar",
  ];

  static values = {
    currentStep: Number,
  };

  connect() {
    this.totalSteps = this.stepTargets.length;
    this.stepTitles = [
      "Choose your brand",
      "Select product line",
      "Pick your paint",
      "Add details",
    ];

    // Listen for cascading select changes
    this.element.addEventListener(
      "cascading-select:changed",
      this.handleCascadingChange.bind(this),
    );

    this.updateUI();
    this.validateCurrentStep();
  }

  nextStep() {
    if (
      this.validateCurrentStep() &&
      this.currentStepValue < this.totalSteps - 1
    ) {
      this.currentStepValue++;
      this.updateUI();
      this.validateCurrentStep();
      this.scrollToTop();
    }
  }

  previousStep() {
    if (this.currentStepValue > 0) {
      this.currentStepValue--;
      this.updateUI();
      this.validateCurrentStep();
      this.scrollToTop();
    }
  }

  updateUI() {
    // Update step visibility
    this.stepTargets.forEach((step, index) => {
      if (index === this.currentStepValue) {
        step.classList.remove("hidden");
        step.classList.add("animate-fade-in");
      } else {
        step.classList.add("hidden");
        step.classList.remove("animate-fade-in");
      }
    });

    // Update step title
    if (this.hasStepTitleTarget) {
      this.stepTitleTarget.textContent = this.stepTitles[this.currentStepValue];
    }

    // Update step counter
    if (this.hasCurrentStepNumberTarget) {
      this.currentStepNumberTarget.textContent = this.currentStepValue + 1;
    }

    // Update progress
    const progress = ((this.currentStepValue + 1) / this.totalSteps) * 100;
    if (this.hasProgressPercentTarget) {
      this.progressPercentTarget.textContent = Math.round(progress);
    }
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${progress}%`;
    }

    // Update button visibility
    this.updateButtons();

    // Update back button visibility (mobile)
    if (this.hasBackButtonTarget) {
      if (this.currentStepValue > 0) {
        this.backButtonTarget.classList.remove("hidden");
      } else {
        this.backButtonTarget.classList.add("hidden");
      }
    }
  }

  updateButtons() {
    const isLastStep = this.currentStepValue === this.totalSteps - 1;

    // Previous button
    if (this.hasPrevButtonTarget) {
      if (this.currentStepValue === 0) {
        this.prevButtonTarget.classList.add("hidden");
      } else {
        this.prevButtonTarget.classList.remove("hidden");
      }
    }

    // Next vs Submit button
    if (isLastStep) {
      if (this.hasNextButtonTarget) {
        this.nextButtonTarget.classList.add("hidden");
      }
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.classList.remove("hidden");
      }
    } else {
      if (this.hasNextButtonTarget) {
        this.nextButtonTarget.classList.remove("hidden");
      }
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.classList.add("hidden");
      }
    }
  }

  validateCurrentStep() {
    let isValid = false;

    switch (this.currentStepValue) {
      case 0: // Brand selection
        const brandSelect = document.getElementById("brand_id");
        isValid = brandSelect && brandSelect.value !== "";
        break;

      case 1: // Product line selection
        const productLineSelect = document.getElementById("product_line_id");
        isValid = productLineSelect && productLineSelect.value !== "";
        break;

      case 2: // Paint selection
        const paintSelect = document.getElementById("user_paint_paint_id");
        isValid = paintSelect && paintSelect.value !== "";
        break;

      case 3: // Details (status is required)
        const statusInputs = document.querySelectorAll(
          'input[name="user_paint[status]"]',
        );
        isValid = Array.from(statusInputs).some((input) => input.checked);
        break;
    }

    // Enable/disable next button based on validation
    if (this.hasNextButtonTarget) {
      if (isValid) {
        this.nextButtonTarget.disabled = false;
        this.nextButtonTarget.classList.remove("btn-disabled");
      } else {
        this.nextButtonTarget.disabled = true;
        this.nextButtonTarget.classList.add("btn-disabled");
      }
    }

    // Enable/disable submit button on last step
    if (
      this.hasSubmitButtonTarget &&
      this.currentStepValue === this.totalSteps - 1
    ) {
      if (isValid) {
        this.submitButtonTarget.disabled = false;
        this.submitButtonTarget.classList.remove("btn-disabled");
      } else {
        this.submitButtonTarget.disabled = true;
        this.submitButtonTarget.classList.add("btn-disabled");
      }
    }

    return isValid;
  }

  handleCascadingChange(event) {
    // Validate current step when cascading selects change
    this.validateCurrentStep();

    // Auto-advance to next step if current step is valid
    const { type, value } = event.detail;

    if (value && this.validateCurrentStep()) {
      // Small delay to allow UI to update
      setTimeout(() => {
        // Auto-advance for brand and product line selections
        if (
          (type === "brand" && this.currentStepValue === 0) ||
          (type === "productLine" && this.currentStepValue === 1)
        ) {
          this.nextStep();
        }
      }, 300);
    }
  }

  handleSubmit(event) {
    // If form submission was successful, we can handle any cleanup here
    if (event.detail.success) {
      // Form was successfully submitted
      // The modal controller will handle closing
    }
  }

  scrollToTop() {
    // Scroll the modal content to top when changing steps
    const modalBox = this.element.querySelector(".modal-box");
    if (modalBox) {
      modalBox.scrollTop = 0;
    }
  }

  // Handle direct step navigation (if needed)
  goToStep(event) {
    const targetStep = parseInt(event.params.step);
    if (targetStep >= 0 && targetStep < this.totalSteps) {
      this.currentStepValue = targetStep;
      this.updateUI();
      this.validateCurrentStep();
      this.scrollToTop();
    }
  }
}
