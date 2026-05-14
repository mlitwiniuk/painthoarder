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
    "brandSelect",
    "productLineSelect",
    "paintSelect",
    "statusRadio",
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

    this.updateUI();
    this.validateCurrentStep();

    // Check for edit mode once the cascading selects finish initializing.
    // The timeout is a fallback; paint-selected fires when the edit chain
    // (which now lazy-fetches paints) has populated the paint select.
    this.checkForEditModeHandler = () => this.checkForEditMode();
    this.element.addEventListener("paint-selected", this.checkForEditModeHandler);
    setTimeout(this.checkForEditModeHandler, 500);
  }

  disconnect() {
    this.element.removeEventListener(
      "paint-selected",
      this.checkForEditModeHandler,
    );
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

  // Action for brand selection change
  brandChanged() {
    this.validateCurrentStep();

    // Auto-advance if valid
    if (this.validateCurrentStep() && this.currentStepValue === 0) {
      setTimeout(() => {
        this.nextStep();
      }, 300);
    }
  }

  // Action for product line selection change
  productLineChanged() {
    this.validateCurrentStep();

    // Auto-advance if valid
    if (this.validateCurrentStep() && this.currentStepValue === 1) {
      setTimeout(() => {
        this.nextStep();
      }, 300);
    }
  }

  // Action for paint selection change
  paintChanged() {
    this.validateCurrentStep();
  }

  // Action for status radio change
  statusChanged() {
    this.validateCurrentStep();
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
        if (this.hasBrandSelectTarget) {
          isValid = this.brandSelectTarget.value !== "";
        }
        break;

      case 1: // Product line selection
        if (this.hasProductLineSelectTarget) {
          isValid = this.productLineSelectTarget.value !== "";
        }
        break;

      case 2: // Paint selection
        if (this.hasPaintSelectTarget) {
          isValid = this.paintSelectTarget.value !== "";
        }
        break;

      case 3: // Details (status is required)
        if (this.hasStatusRadioTarget) {
          isValid = this.statusRadioTargets.some((radio) => radio.checked);
        }
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

  checkForEditMode() {
    // Check if we're in edit mode with existing paint selection
    if (this.hasPaintSelectTarget && this.paintSelectTarget.value) {
      // We have a paint selected, go to paint selection step (step 2)
      this.currentStepValue = 2;
      this.updateUI();
      this.validateCurrentStep();
    } else if (
      this.hasProductLineSelectTarget &&
      this.productLineSelectTarget.value
    ) {
      // We have a product line selected, go to product line step (step 1)
      this.currentStepValue = 1;
      this.updateUI();
      this.validateCurrentStep();
    } else if (this.hasBrandSelectTarget && this.brandSelectTarget.value) {
      // We have a brand selected, stay on brand step (step 0)
      this.currentStepValue = 0;
      this.updateUI();
      this.validateCurrentStep();
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
