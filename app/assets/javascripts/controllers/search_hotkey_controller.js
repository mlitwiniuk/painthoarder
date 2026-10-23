import { Controller } from "@hotwired/stimulus";

// Focuses the global paint search when "/" is pressed outside a text field.
export default class extends Controller {
  static targets = ["input"];

  connect() {
    this.handler = this.focus.bind(this);
    window.addEventListener("keydown", this.handler);
  }

  disconnect() {
    window.removeEventListener("keydown", this.handler);
  }

  focus(event) {
    if (event.key !== "/" || event.metaKey || event.ctrlKey || event.altKey) return;

    const el = document.activeElement;
    if (el && (el.isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(el.tagName))) return;

    event.preventDefault();
    this.inputTarget.focus();
  }
}
