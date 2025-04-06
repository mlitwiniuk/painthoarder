import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content", "label", "icon"];

  toggle() {
    const isHidden = this.contentTarget.classList.toggle("hidden");
    this.labelTarget.textContent = isHidden ? "Show Filters" : "Hide Filters";
    this.iconTarget.classList.toggle("rotate-180", !isHidden);
  }
}
