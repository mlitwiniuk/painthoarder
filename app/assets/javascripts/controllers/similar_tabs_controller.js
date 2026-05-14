import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tab", "content"];

  connect() {
    // Set initial state - first tab active
    this.showTab("color");
  }

  switch(event) {
    event.preventDefault();
    const tabType = event.currentTarget.dataset.tab;
    this.showTab(tabType);
  }

  showTab(tabType) {
    // Update tab button states
    this.tabTargets.forEach((tab) => {
      if (tab.dataset.tab === tabType) {
        tab.classList.remove("text-base-content/60", "hover:text-base-content");
        tab.classList.add("bg-base-100", "text-base-content", "shadow-sm");
      } else {
        tab.classList.remove("bg-base-100", "text-base-content", "shadow-sm");
        tab.classList.add("text-base-content/60", "hover:text-base-content");
      }
    });

    // Update content visibility
    this.contentTargets.forEach((content) => {
      if (content.id === `${tabType}-content`) {
        content.classList.remove("hidden");
      } else {
        content.classList.add("hidden");
      }
    });
  }
}
