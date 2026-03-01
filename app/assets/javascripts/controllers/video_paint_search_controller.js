import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "results", "paintId", "form"];

  connect() {
    this.timeout = null;
    this.handleClickOutside = this.handleClickOutside.bind(this);
    document.addEventListener("click", this.handleClickOutside);
  }

  disconnect() {
    clearTimeout(this.timeout);
    document.removeEventListener("click", this.handleClickOutside);
  }

  search() {
    clearTimeout(this.timeout);
    const query = this.inputTarget.value.trim();

    if (query.length < 2) {
      this.resultsTarget.innerHTML = "";
      this.resultsTarget.classList.add("hidden");
      return;
    }

    this.timeout = setTimeout(() => {
      fetch(`/api/paints?query=${encodeURIComponent(query)}`, {
        headers: { Accept: "application/json" },
      })
        .then((response) => response.json())
        .then((paints) => this.renderResults(paints));
    }, 300);
  }

  renderResults(paints) {
    if (paints.length === 0) {
      this.resultsTarget.innerHTML =
        '<div class="p-3 text-sm text-base-content/50">No paints found</div>';
      this.resultsTarget.classList.remove("hidden");
      return;
    }

    const html = paints
      .slice(0, 20)
      .map(
        (paint) => `
      <button type="button"
              class="w-full text-left px-3 py-2 hover:bg-base-200 flex items-center gap-2 cursor-pointer"
              data-action="click->video-paint-search#select"
              data-paint-id="${paint.id}"
              data-paint-name="${this.escapeHtml(paint.text)}">
        <span class="w-5 h-5 rounded border border-base-300 flex-shrink-0"
              style="background-color: ${paint.color || "#ccc"};"></span>
        <span class="flex-1 min-w-0">
          <span class="text-sm font-medium truncate block">${this.escapeHtml(paint.text)}</span>
          ${paint.brand_name ? `<span class="text-xs text-base-content/50">${this.escapeHtml(paint.brand_name)} — ${this.escapeHtml(paint.product_line_name || "")}</span>` : ""}
        </span>
      </button>
    `
      )
      .join("");

    this.resultsTarget.innerHTML = html;
    this.resultsTarget.classList.remove("hidden");
  }

  select(event) {
    event.preventDefault();
    const button = event.currentTarget;
    const paintId = button.dataset.paintId;

    this.paintIdTarget.value = paintId;
    this.resultsTarget.innerHTML = "";
    this.resultsTarget.classList.add("hidden");
    this.formTarget.requestSubmit();
  }

  clear(event) {
    event.preventDefault();
    this.paintIdTarget.value = "";
    this.formTarget.requestSubmit();
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.resultsTarget.classList.add("hidden");
    }
  }

  escapeHtml(str) {
    if (!str) return "";
    const div = document.createElement("div");
    div.textContent = str;
    return div.innerHTML;
  }
}
