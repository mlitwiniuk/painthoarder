import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["search", "results", "selectedPaints"];

  connect() {
    this.selectedPaintIds = new Set();
    this.searchTimeout = null;
    this.paintUsageIndex = 0;
  }

  search(event) {
    console.log("Searching for:", event.target.value);
    const query = event.target.value.trim();

    // Clear previous timeout
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }

    // Hide results if query is empty
    if (query.length < 2) {
      this.hideResults();
      return;
    }

    // Debounce search
    this.searchTimeout = setTimeout(() => {
      this.performSearch(query);
    }, 300);
  }

  async performSearch(query) {
    try {
      const response = await fetch(
        `/user_paints.json?search=${encodeURIComponent(query)}&limit=10`,
        {
          headers: {
            Accept: "application/json",
            "X-Requested-With": "XMLHttpRequest",
          },
        },
      );

      if (response.ok) {
        const data = await response.json();
        this.displayResults(data.user_paints || []);
      }
    } catch (error) {
      console.error("Error searching paints:", error);
    }
  }

  displayResults(paints) {
    console.log("Displaying results");
    if (paints.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="p-3 text-center text-base-content/60">
          <p>No paints found in your collection</p>
        </div>
      `;
      this.showResults();
      return;
    }

    const resultsHTML = paints
      .map((userPaint) => {
        const isSelected = this.selectedPaintIds.has(userPaint.id);
        const paint = userPaint.paint;

        return `
        <div class="flex items-center justify-between p-3 hover:bg-base-200 border-b border-base-300 last:border-b-0 ${isSelected ? "bg-primary/10" : ""}"
             data-paint-id="${userPaint.id}">
          <div class="flex items-center gap-3 flex-1 min-w-0">
            <div class="w-6 h-6 rounded-full border-2 border-base-300 flex-shrink-0"
                 style="background-color: ${paint.hex_color}"></div>
            <div class="flex-1 min-w-0">
              <p class="font-medium text-base-content truncate">${paint.name}</p>
              <p class="text-sm text-base-content/60 truncate">
                ${paint.product_line.brand.name} • ${paint.product_line.name}
              </p>
            </div>
          </div>
          <button type="button"
                  class="btn btn-sm ${isSelected ? "btn-error" : "btn-primary"}"
                  data-action="click->paint-selector#${isSelected ? "removePaint" : "addPaint"}"
                  data-paint-id="${userPaint.id}"
                  data-paint-name="${paint.name}"
                  data-paint-color="${paint.hex_color}"
                  data-brand-name="${paint.product_line.brand.name}"
                  data-line-name="${paint.product_line.name}">
            ${isSelected ? "Remove" : "Add"}
          </button>
        </div>
      `;
      })
      .join("");

    this.resultsTarget.innerHTML = resultsHTML;
    this.showResults();
  }

  addPaint(event) {
    const button = event.currentTarget;
    const paintId = parseInt(button.dataset.paintId);
    const paintName = button.dataset.paintName;
    const paintColor = button.dataset.paintColor;
    const brandName = button.dataset.brandName;
    const lineName = button.dataset.lineName;

    if (this.selectedPaintIds.has(paintId)) {
      return; // Already selected
    }

    this.selectedPaintIds.add(paintId);
    this.addPaintToSelection(
      paintId,
      paintName,
      paintColor,
      brandName,
      lineName,
    );
    this.updateButtonState(button, true);
    this.clearSearch();
  }

  removePaint(event) {
    const button = event.currentTarget;
    const paintId = parseInt(button.dataset.paintId);

    this.selectedPaintIds.delete(paintId);
    this.removePaintFromSelection(paintId);
    this.updateButtonState(button, false);
  }

  addPaintToSelection(paintId, paintName, paintColor, brandName, lineName) {
    const selectedContainer = this.selectedPaintsTarget;

    // Remove empty state if it exists
    if (selectedContainer.querySelector(".text-center")) {
      selectedContainer.innerHTML = "";
    }

    // Create paint badge
    const paintBadge = document.createElement("div");
    paintBadge.className =
      "flex items-center gap-2 bg-base-100 border border-base-300 rounded-lg p-2";
    paintBadge.dataset.paintId = paintId;
    paintBadge.innerHTML = `
      <div class="w-4 h-4 rounded-full border border-base-300 flex-shrink-0"
           style="background-color: ${paintColor}"></div>
      <div class="flex-1 min-w-0">
        <p class="font-medium text-sm text-base-content truncate">${paintName}</p>
        <p class="text-xs text-base-content/60 truncate">${brandName} • ${lineName}</p>
      </div>
      <button type="button"
              class="btn btn-ghost btn-xs text-error hover:bg-error hover:text-error-content"
              data-action="click->paint-selector#removePaintFromBadge"
              data-paint-id="${paintId}">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    `;

    selectedContainer.appendChild(paintBadge);

    // Add hidden form field
    this.addHiddenFormField(paintId);
  }

  removePaintFromSelection(paintId) {
    const badge = this.selectedPaintsTarget.querySelector(
      `[data-paint-id="${paintId}"]`,
    );
    if (badge) {
      badge.remove();
    }

    this.removeHiddenFormField(paintId);

    // Show empty state if no paints selected
    if (this.selectedPaintIds.size === 0) {
      this.showEmptyState();
    }
  }

  removePaintFromBadge(event) {
    const button = event.currentTarget;
    const paintId = parseInt(button.dataset.paintId);

    this.selectedPaintIds.delete(paintId);
    this.removePaintFromSelection(paintId);

    // Update any visible buttons in search results
    const searchButton = this.resultsTarget.querySelector(
      `button[data-paint-id="${paintId}"]`,
    );
    if (searchButton) {
      this.updateButtonState(searchButton, false);
    }
  }

  addHiddenFormField(paintId) {
    const form = this.element.closest("form");
    if (!form) return;

    const input = document.createElement("input");
    input.type = "hidden";
    input.name = `project_update[paint_usages_attributes][${this.paintUsageIndex}][user_paint_id]`;
    input.value = paintId;
    input.dataset.paintId = paintId;
    input.dataset.paintUsageIndex = this.paintUsageIndex;

    form.appendChild(input);
    this.paintUsageIndex++;
  }

  removeHiddenFormField(paintId) {
    const form = this.element.closest("form");
    if (!form) return;

    const input = form.querySelector(`input[data-paint-id="${paintId}"]`);
    if (input) {
      input.remove();
    }
  }

  updateButtonState(button, isSelected) {
    if (isSelected) {
      button.textContent = "Remove";
      button.className = "btn btn-sm btn-error";
      button.dataset.action = "click->paint-selector#removePaint";
    } else {
      button.textContent = "Add";
      button.className = "btn btn-sm btn-primary";
      button.dataset.action = "click->paint-selector#addPaint";
    }

    // Update parent row styling
    const row = button.closest("[data-paint-id]");
    if (row) {
      if (isSelected) {
        row.classList.add("bg-primary/10");
      } else {
        row.classList.remove("bg-primary/10");
      }
    }
  }

  showEmptyState() {
    this.selectedPaintsTarget.innerHTML = `
      <div class="text-center text-base-content/50 text-sm py-4">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 mx-auto mb-2 opacity-50" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zM21 5a2 2 0 00-2-2h-4a2 2 0 00-2 2v12a4 4 0 004 4 4 4 0 004-4V5z" />
        </svg>
        Search and add paints you used in this session
      </div>
    `;
  }

  showResults() {
    this.resultsTarget.classList.remove("hidden");
  }

  hideResults() {
    this.resultsTarget.classList.add("hidden");
  }

  clearSearch() {
    this.searchTarget.value = "";
    this.hideResults();
  }

  disconnect() {
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }
  }
}
