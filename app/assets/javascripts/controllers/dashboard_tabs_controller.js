import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["recent", "insights", "wishlist"];

  connect() {
    // Initially show the recent activity tab
    this.showTab("recent");
  }

  activate(event) {
    event.preventDefault();
    const target = event.currentTarget.dataset.tabTarget;
    this.showTab(target);
  }

  showTab(targetTab) {
    // Update tab button states
    const tabs = this.element.querySelectorAll(".tab");
    tabs.forEach((tab) => {
      const tabTarget = tab.dataset.tabTarget;
      if (tabTarget === targetTab) {
        // Active tab styling
        tab.classList.remove("text-base-content/60", "hover:text-base-content");
        tab.classList.add(
          "tab-active",
          "bg-primary",
          "text-primary-content",
          "shadow-sm",
        );
      } else {
        // Inactive tab styling
        tab.classList.remove(
          "tab-active",
          "bg-primary",
          "text-primary-content",
          "shadow-sm",
        );
        tab.classList.add("text-base-content/60", "hover:text-base-content");
      }
    });

    // Update tab pane visibility
    const panes = document.querySelectorAll(".tab-pane");
    panes.forEach((pane) => {
      if (pane.id === `${targetTab}-tab`) {
        pane.classList.remove("hidden");
        pane.classList.add("block");
      } else {
        pane.classList.remove("block");
        pane.classList.add("hidden");
      }
    });
  }
}
