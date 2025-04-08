import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["clearFiltersInput"];
  
  static values = {
    delay: { type: Number, default: 500 },
  };

  submit() {
    this.element.requestSubmit();
  }

  debouncedSubmit() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.submit();
    }, this.delayValue);
  }
  
  clearFilters(event) {
    // Prevent the default click action
    event.preventDefault();
    
    // Get all form inputs and reset them
    const form = this.element;
    
    // Clear text fields and selects (except status for user_paints)
    form.querySelectorAll('input[type="text"], select').forEach(input => {
      // Skip status select if present (in case of user_paints)
      if (input.name !== 'status') {
        input.value = '';
      }
    });
    
    // Reset hidden Ransack fields
    form.querySelectorAll('input[type="hidden"]').forEach(input => {
      // Skip the authenticity token and status params
      if (!input.name.includes('authenticity_token') && 
          !input.name.includes('status') && 
          input.name !== 'clear_filters') {
        input.value = '';
      }
    });
    
    // Set the clear_filters flag to true
    if (this.hasClearFiltersInputTarget) {
      this.clearFiltersInputTarget.value = 'true';
    }
    
    // Submit the form
    this.submit();
  }
}
