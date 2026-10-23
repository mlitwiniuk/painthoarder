import { Controller } from "@hotwired/stimulus";

// Switches the paint page's "Swap it for another brand" panels.
export default class extends Controller {
  static targets = ["tab", "content"];

  connect() {
    this.showTab("color");
  }

  switch(event) {
    event.preventDefault();
    this.showTab(event.currentTarget.dataset.tab);
  }

  showTab(tabType) {
    this.tabTargets.forEach((tab) => {
      tab.setAttribute("aria-selected", tab.dataset.tab === tabType ? "true" : "false");
    });

    this.contentTargets.forEach((content) => {
      content.classList.toggle("hidden", content.id !== `${tabType}-content`);
    });
  }
}
