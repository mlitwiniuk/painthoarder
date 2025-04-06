import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    document.addEventListener("keydown", (event) => {
      if (
        event.key === "Escape" &&
        !this.element.classList.contains("hidden")
      ) {
        this.close();
      }
    });
  }

  open(event) {
    const modalId = event.params.id || event.target.dataset.modalId;
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.classList.remove("hidden");
    }
  }

  close() {
    this.element.classList.add("hidden");
  }
}
