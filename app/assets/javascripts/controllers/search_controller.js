import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "results"];

  connect() {
    this.timeout = null;
  }

  search() {
    clearTimeout(this.timeout);

    const query = this.inputTarget.value.trim();

    if (query.length < 2) {
      this.resultsTarget.innerHTML =
        '<p class="text-center py-4 text-base-content/70">Type to search for paints</p>';
      return;
    }

    this.timeout = setTimeout(() => {
      fetch(`/paints/search?query=${encodeURIComponent(query)}`, {
        headers: {
          Accept: "text/vnd.turbo-stream.html",
        },
      })
        .then((response) => response.text())
        .then((html) => {
          Turbo.renderStreamMessage(html);
        });
    }, 300);
  }
}
