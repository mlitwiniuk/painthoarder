import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["owned", "wishlist", "avoid"];

  connect() {
    // Initially hide all tab content except the first one
    document.querySelectorAll(".tab-pane").forEach((pane) => {
      if (pane.id === "owned-tab") {
        pane.classList.remove("hidden");
        pane.classList.add("active");
      } else {
        pane.classList.add("hidden");
        pane.classList.remove("active");
      }
    });
  }

  activate(event) {
    // First, make all tabs inactive
    document.querySelectorAll(".tab").forEach((tab) => {
      tab.classList.remove("tab-active");
    });

    // Make clicked tab active
    event.currentTarget.classList.add("tab-active");

    // Hide all tab content
    document.querySelectorAll(".tab-pane").forEach((pane) => {
      pane.classList.add("hidden");
      pane.classList.remove("active");
    });

    // Show the corresponding tab content
    const target = event.currentTarget.dataset.tabTarget;
    const tabContent = document.getElementById(`${target}-tab`);
    if (tabContent) {
      tabContent.classList.remove("hidden");
      tabContent.classList.add("active");
    }
  }
}
